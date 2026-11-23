#include "api/ApiClient.hpp"

#include "core/Util.hpp"

namespace tt {
namespace {

Headers jsonHeaders() { return Headers{{"Content-Type", "application/json"}}; }

std::string withQuery(std::string path, const QueryBuilder& query) {
    if (!query.empty()) {
        path += '?';
        path += query.str();
    }
    return path;
}

// A strong ETag is the quoted version: version 3 is sent as "3" including the quotes.
std::string quoted(int version) { return '"' + std::to_string(version) + '"'; }

}  // namespace

ApiClient::ApiClient(Transport& transport, std::string baseUrl, TokenProvider tokens)
    : transport_{&transport}, baseUrl_{std::move(baseUrl)}, tokens_{std::move(tokens)} {}

Result<HttpResponse> ApiClient::call(Method method, const std::string& path, Headers headers, std::string body,
                                     bool authenticated, std::stop_token stop) const {
    HttpRequest request;
    request.method = method;
    request.url = baseUrl_ + path;
    request.headers = std::move(headers);
    request.headers.emplace_back("Accept", "application/json");
    request.body = std::move(body);
    if (authenticated && tokens_) {
        auto token = tokens_(stop);
        if (!token) {
            return tl::make_unexpected(std::move(token.error()));
        }
        if (!token->empty()) {
            request.headers.emplace_back("Authorization", "Bearer " + *token);
        }
    }
    auto response = transport_->send(request, stop);
    if (!response) {
        return response;
    }
    if (response->status < 200 || response->status >= 300) {
        return tl::make_unexpected(problemFromResponse(*response));
    }
    return response;
}

template <class T>
Result<T> ApiClient::fetch(Method method, const std::string& path, Headers headers, std::string body,
                           bool authenticated, std::stop_token stop) const {
    auto response = call(method, path, std::move(headers), std::move(body), authenticated, stop);
    if (!response) {
        return tl::make_unexpected(std::move(response.error()));
    }
    return decode<T>(response->body);
}

Result<Health> ApiClient::health(std::stop_token stop) const {
    return fetch<Health>(Method::Get, "/health", {}, {}, false, stop);
}

Result<Me> ApiClient::me(std::stop_token stop) const {
    return fetch<Me>(Method::Get, "/v1/me", {}, {}, true, stop);
}

Result<Page<Team>> ApiClient::listTeams(const std::optional<std::string>& cursor, std::stop_token stop) const {
    QueryBuilder query;
    query.add("limit", "25");
    if (cursor) {
        query.add("cursor", *cursor);
    }
    return fetch<Page<Team>>(Method::Get, withQuery("/v1/teams", query), {}, {}, true, stop);
}

Result<Page<Project>> ApiClient::listProjects(const std::string& teamId, const std::optional<std::string>& cursor,
                                              std::stop_token stop) const {
    QueryBuilder query;
    query.add("limit", "25");
    if (cursor) {
        query.add("cursor", *cursor);
    }
    return fetch<Page<Project>>(Method::Get, withQuery("/v1/teams/" + urlEncode(teamId) + "/projects", query), {}, {},
                                true, stop);
}

Result<Page<Task>> ApiClient::listTasks(const std::string& projectId, const TaskQuery& query,
                                        const std::optional<std::string>& cursor, std::stop_token stop) const {
    QueryBuilder params;
    params.add("limit", std::to_string(query.limit));
    params.add("sort", query.sort);
    for (const auto& status : query.statuses) {
        params.add("status", status);
    }
    if (!query.text.empty()) {
        params.add("q", query.text);
    }
    if (cursor) {
        params.add("cursor", *cursor);
    }
    return fetch<Page<Task>>(Method::Get, withQuery("/v1/projects/" + urlEncode(projectId) + "/tasks", params), {}, {},
                             true, stop);
}

Result<Task> ApiClient::getTask(const std::string& id, std::stop_token stop) const {
    return fetch<Task>(Method::Get, "/v1/tasks/" + urlEncode(id), {}, {}, true, stop);
}

Result<Task> ApiClient::createTask(const std::string& projectId, const TaskCreate& body, const std::string& idempotencyKey,
                                   std::stop_token stop) const {
    Headers headers = jsonHeaders();
    if (!idempotencyKey.empty()) {
        headers.emplace_back("Idempotency-Key", idempotencyKey);
    }
    return fetch<Task>(Method::Post, "/v1/projects/" + urlEncode(projectId) + "/tasks", std::move(headers),
                       dumpJson(toJson(body)), true, stop);
}

Result<Task> ApiClient::updateTask(const std::string& id, int version, const nlohmann::json& mergePatch,
                                   std::stop_token stop) const {
    Headers headers{{"Content-Type", "application/merge-patch+json"}, {"If-Match", quoted(version)}};
    return fetch<Task>(Method::Patch, "/v1/tasks/" + urlEncode(id), std::move(headers), dumpJson(mergePatch), true,
                       stop);
}

Result<void> ApiClient::deleteTask(const std::string& id, int version, std::stop_token stop) const {
    auto response = call(Method::Delete, "/v1/tasks/" + urlEncode(id), Headers{{"If-Match", quoted(version)}}, {}, true,
                         stop);
    if (!response) {
        return tl::make_unexpected(std::move(response.error()));
    }
    return {};
}

}  // namespace tt
