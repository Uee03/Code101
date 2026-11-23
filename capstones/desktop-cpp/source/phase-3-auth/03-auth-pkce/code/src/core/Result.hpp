#pragma once

#include <nlohmann/json.hpp>
#include <tl/expected.hpp>

#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace tt {

enum class ErrorKind { Network, Http, Parse, Auth, Config, Cancelled };

struct FieldError {
    std::string pointer;  // JSON Pointer (RFC 6901), for example "/title"
    std::string detail;
};

// One error type for every layer: transport, HTTP problem details, parsing, sign-in and configuration.
struct Problem {
    ErrorKind kind{ErrorKind::Http};
    int status{0};
    std::string type;
    std::string title;
    std::string detail;
    std::string traceId;
    std::vector<FieldError> errors;
    std::optional<int> retryAfterSeconds;
};

// tl::expected has the interface of C++23 std::expected, so a later move to the standard type is a rename.
template <class T>
using Result = tl::expected<T, Problem>;

[[nodiscard]] inline tl::unexpected<Problem> failure(ErrorKind kind, std::string title, std::string detail = {}) {
    Problem problem;
    problem.kind = kind;
    problem.title = std::move(title);
    problem.detail = std::move(detail);
    return tl::make_unexpected(std::move(problem));
}

// "https://code101.example/problems/not-found" gives "not-found".
[[nodiscard]] inline std::string problemSlug(const Problem& problem) {
    const auto slash = problem.type.rfind('/');
    return slash == std::string::npos ? problem.type : problem.type.substr(slash + 1);
}

[[nodiscard]] inline std::string jsonString(const nlohmann::json& json, const char* key) {
    const auto found = json.find(key);
    return (found != json.end() && found->is_string()) ? found->get<std::string>() : std::string{};
}

[[nodiscard]] inline std::optional<std::string> jsonOptString(const nlohmann::json& json, const char* key) {
    const auto found = json.find(key);
    if (found == json.end() || !found->is_string()) {
        return std::nullopt;
    }
    return found->get<std::string>();
}

}  // namespace tt
