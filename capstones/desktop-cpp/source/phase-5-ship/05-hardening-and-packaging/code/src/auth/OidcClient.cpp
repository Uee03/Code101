#include "auth/OidcClient.hpp"

#include <nlohmann/json.hpp>

namespace tt {
namespace {

constexpr int kDefaultLifetimeSeconds = 60;

Headers formHeaders() {
    return Headers{{"Content-Type", "application/x-www-form-urlencoded"}, {"Accept", "application/json"}};
}

}  // namespace

OidcClient::OidcClient(Config config, Transport& transport) : config_{std::move(config)}, transport_{&transport} {}

Result<Endpoints> OidcClient::discover(std::stop_token stop) const {
    HttpRequest request;
    request.url = config_.issuer + "/.well-known/openid-configuration";
    request.headers = Headers{{"Accept", "application/json"}};
    const auto response = transport_->send(request, stop);
    if (!response) {
        return tl::make_unexpected(response.error());
    }
    if (response->status != 200) {
        return tl::make_unexpected(problemFromResponse(*response));
    }
    const auto document = nlohmann::json::parse(response->body, nullptr, false);
    if (!document.is_object() || jsonString(document, "issuer") != config_.issuer) {
        return failure(ErrorKind::Auth, "Unexpected identity provider",
                       "The discovery document names a different issuer than the configured one.");
    }
    Endpoints endpoints{jsonString(document, "authorization_endpoint"), jsonString(document, "token_endpoint"),
                        jsonString(document, "end_session_endpoint")};
    if (endpoints.authorization.empty() || endpoints.token.empty()) {
        return failure(ErrorKind::Parse, "The discovery document is incomplete");
    }
    // The document comes from the network: its addresses must obey the same rule as our own configuration.
    for (const std::string* url : {&endpoints.authorization, &endpoints.token, &endpoints.endSession}) {
        if (!url->empty() && !isAllowedUrl(*url)) {
            return failure(ErrorKind::Auth, "Unexpected identity provider",
                           "The discovery document points to an address that is neither https nor loopback.");
        }
    }
    return endpoints;
}

std::string OidcClient::authorizationUrl(const Endpoints& endpoints, const std::string& redirectUri,
                                         const Pkce& pkce) const {
    QueryBuilder query;
    query.add("response_type", "code")
        .add("client_id", config_.clientId)
        .add("redirect_uri", redirectUri)
        .add("scope", config_.scope)
        .add("state", pkce.state)
        .add("code_challenge", pkce.challenge)
        .add("code_challenge_method", "S256");
    return endpoints.authorization + "?" + query.str();
}

Result<TokenSet> OidcClient::exchangeCode(const Endpoints& endpoints, const std::string& code,
                                          const std::string& verifier, const std::string& redirectUri,
                                          std::stop_token stop) const {
    QueryBuilder form;
    form.add("grant_type", "authorization_code")
        .add("code", code)
        .add("redirect_uri", redirectUri)
        .add("client_id", config_.clientId)
        .add("code_verifier", verifier);
    return tokenRequest(endpoints, form, stop);
}

Result<TokenSet> OidcClient::refresh(const Endpoints& endpoints, const std::string& refreshToken,
                                     std::stop_token stop) const {
    QueryBuilder form;
    form.add("grant_type", "refresh_token").add("refresh_token", refreshToken).add("client_id", config_.clientId);
    return tokenRequest(endpoints, form, stop);
}

Result<void> OidcClient::endSession(const Endpoints& endpoints, const std::string& refreshToken,
                                    std::stop_token stop) const {
    if (endpoints.endSession.empty()) {
        return {};
    }
    QueryBuilder form;
    form.add("client_id", config_.clientId).add("refresh_token", refreshToken);
    HttpRequest request;
    request.method = Method::Post;
    request.url = endpoints.endSession;
    request.headers = formHeaders();
    request.body = form.str();
    request.timeout = std::chrono::seconds{5};
    const auto response = transport_->send(request, stop);
    if (!response) {
        return tl::make_unexpected(response.error());
    }
    if (response->status < 200 || response->status >= 300) {
        return tl::make_unexpected(problemFromResponse(*response));
    }
    return {};
}

Result<TokenSet> OidcClient::tokenRequest(const Endpoints& endpoints, const QueryBuilder& form,
                                          std::stop_token stop) const {
    HttpRequest request;
    request.method = Method::Post;
    request.url = endpoints.token;
    request.headers = formHeaders();
    request.body = form.str();
    const auto response = transport_->send(request, stop);
    if (!response) {
        return tl::make_unexpected(response.error());
    }
    const auto json = nlohmann::json::parse(response->body, nullptr, false);
    if (response->status != 200) {
        // OAuth errors are {"error": "invalid_grant", "error_description": "..."} (RFC 6749 section 5.2).
        Problem problem = problemFromResponse(*response);
        problem.kind = ErrorKind::Auth;
        problem.title = "Sign-in failed";
        problem.type = "oauth/" + jsonString(json, "error");
        problem.detail = jsonString(json, "error_description");
        return tl::make_unexpected(std::move(problem));
    }
    if (!json.is_object() || jsonString(json, "access_token").empty()) {
        return failure(ErrorKind::Parse, "The identity provider answer was not understood");
    }
    int lifetime = kDefaultLifetimeSeconds;
    if (const auto found = json.find("expires_in"); found != json.end() && found->is_number_integer()) {
        lifetime = found->get<int>();
    }
    TokenSet tokens;
    tokens.access = Secret{jsonString(json, "access_token")};
    tokens.refresh = Secret{jsonString(json, "refresh_token")};
    tokens.accessExpiresAt = std::chrono::steady_clock::now() + std::chrono::seconds{lifetime};
    return tokens;
}

}  // namespace tt
