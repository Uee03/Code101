#pragma once

#include "core/Result.hpp"
#include "core/Util.hpp"

#include <initializer_list>
#include <string>
#include <string_view>

namespace tt {

struct Config {
    std::string apiBaseUrl;
    std::string issuer;
    std::string clientId{"tasks-desktop"};
    std::string scope{"openid profile email tasks:read tasks:write"};
};

// https anywhere; plain http only for the loopback names. No credentials, query or fragment in the URL.
// A token must never travel in clear text across a network, and "http://localhost.evil.example" is not localhost.
[[nodiscard]] inline bool isAllowedUrl(std::string_view url) {
    const auto schemeEnd = url.find("://");
    if (schemeEnd == std::string_view::npos) {
        return false;
    }
    const std::string_view scheme = url.substr(0, schemeEnd);
    const std::string_view rest = url.substr(schemeEnd + 3);
    if (rest.find_first_of("?#") != std::string_view::npos) {
        return false;
    }
    const std::string_view authority = rest.substr(0, rest.find('/'));
    if (authority.empty() || authority.find('@') != std::string_view::npos) {
        return false;
    }
    std::string_view host = authority;
    if (host.front() == '[') {  // IPv6 literal such as [::1]:8000
        const auto close = host.find(']');
        host = close == std::string_view::npos ? std::string_view{} : host.substr(0, close + 1);
    } else {
        host = host.substr(0, host.find(':'));
    }
    if (host.empty()) {
        return false;
    }
    if (scheme == "https") {
        return true;
    }
    return scheme == "http" && (host == "localhost" || host == "127.0.0.1" || host == "[::1]");
}

[[nodiscard]] inline std::string withoutTrailingSlash(std::string url) {
    while (!url.empty() && url.back() == '/') {
        url.pop_back();
    }
    return url;
}

// Defaults match the platform: API on 8000, Keycloak realm tasksteams on 8180. Both addresses are checked.
[[nodiscard]] inline Result<Config> loadConfig() {
    Config config;
    config.apiBaseUrl = withoutTrailingSlash(envOr("API_BASE_URL", "http://localhost:8000"));
    config.issuer = withoutTrailingSlash(envOr("OIDC_ISSUER", "http://localhost:8180/realms/tasksteams"));
    for (const std::string* url : {&config.apiBaseUrl, &config.issuer}) {
        if (!isAllowedUrl(*url)) {
            return failure(ErrorKind::Config, "Refusing to use this address",
                           *url + " must be https, or http on localhost, 127.0.0.1 or [::1], without credentials, query or fragment.");
        }
    }
    return config;
}

}  // namespace tt
