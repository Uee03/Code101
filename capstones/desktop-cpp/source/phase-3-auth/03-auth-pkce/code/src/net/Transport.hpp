#pragma once

#include "core/Result.hpp"

#include <algorithm>
#include <cctype>
#include <charconv>
#include <chrono>
#include <map>
#include <stop_token>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

namespace tt {

enum class Method { Get, Post, Put, Patch, Delete };

using Headers = std::vector<std::pair<std::string, std::string>>;

// HTTP header names are case-insensitive (platform TDD section 12.1: Go sends "Etag").
struct CaseInsensitiveLess {
    bool operator()(const std::string& a, const std::string& b) const {
        return std::lexicographical_compare(a.begin(), a.end(), b.begin(), b.end(), [](unsigned char x, unsigned char y) {
            return std::tolower(x) < std::tolower(y);
        });
    }
};

struct HttpRequest {
    Method method{Method::Get};
    std::string url;
    Headers headers;
    std::string body;
    std::chrono::milliseconds timeout{10'000};
};

struct HttpResponse {
    int status{0};
    std::string body;
    std::map<std::string, std::string, CaseInsensitiveLess> headers;

    [[nodiscard]] std::string header(const std::string& name) const {
        const auto found = headers.find(name);
        return found == headers.end() ? std::string{} : found->second;
    }
};

// The only door to the network. Tests use a fake; the app uses CprTransport.
class Transport {
public:
    Transport() = default;
    Transport(const Transport&) = delete;
    Transport& operator=(const Transport&) = delete;
    virtual ~Transport() = default;

    // A reply with any HTTP status is a success here; only "no reply" is an error.
    virtual Result<HttpResponse> send(const HttpRequest& request, std::stop_token stop) = 0;
};

// Turns a non-2xx reply into a Problem. Reads RFC 9457 members when the body has them.
[[nodiscard]] inline Problem problemFromResponse(const HttpResponse& response) {
    Problem problem;
    problem.kind = ErrorKind::Http;
    problem.status = response.status;
    problem.title = "HTTP " + std::to_string(response.status);

    const std::string retry = response.header("Retry-After");
    int seconds = 0;
    if (!retry.empty() && std::from_chars(retry.data(), retry.data() + retry.size(), seconds).ec == std::errc{}) {
        problem.retryAfterSeconds = seconds;
    }

    const auto json = nlohmann::json::parse(response.body, nullptr, false);
    if (!json.is_object()) {
        return problem;
    }
    problem.type = jsonString(json, "type");
    if (auto title = jsonString(json, "title"); !title.empty()) {
        problem.title = std::move(title);
    }
    problem.detail = jsonString(json, "detail");
    problem.traceId = jsonString(json, "traceId");
    const auto errors = json.find("errors");
    if (errors != json.end() && errors->is_array()) {
        for (const auto& item : *errors) {
            problem.errors.push_back(FieldError{jsonString(item, "pointer"), jsonString(item, "detail")});
        }
    }
    return problem;
}

}  // namespace tt
