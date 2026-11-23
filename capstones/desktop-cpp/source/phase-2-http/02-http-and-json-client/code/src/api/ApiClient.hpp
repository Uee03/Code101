#pragma once

#include "api/Models.hpp"
#include "net/Transport.hpp"

#include <functional>
#include <optional>
#include <stop_token>
#include <string>
#include <vector>

namespace tt {

// Returns the access token for the next call. An empty string means "send no Authorization header".
using TokenProvider = std::function<Result<std::string>(std::stop_token)>;

struct TaskQuery {
    std::vector<std::string> statuses;  // repeated `status` parameter
    std::string text;                   // `q`, a substring of the title
    std::string sort{"-createdAt"};
    int limit{25};
};

class ApiClient {
public:
    ApiClient(Transport& transport, std::string baseUrl, TokenProvider tokens);

    [[nodiscard]] Result<Health> health(std::stop_token stop = {}) const;
    [[nodiscard]] Result<Me> me(std::stop_token stop = {}) const;
    [[nodiscard]] Result<Page<Team>> listTeams(const std::optional<std::string>& cursor, std::stop_token stop = {}) const;
    [[nodiscard]] Result<Page<Project>> listProjects(const std::string& teamId, const std::optional<std::string>& cursor,
                                                      std::stop_token stop = {}) const;
    [[nodiscard]] Result<Page<Task>> listTasks(const std::string& projectId, const TaskQuery& query,
                                                const std::optional<std::string>& cursor, std::stop_token stop = {}) const;
    [[nodiscard]] Result<Task> getTask(const std::string& id, std::stop_token stop = {}) const;
    // `idempotencyKey` stays the same for every retry of one form; an empty key sends no header.
    [[nodiscard]] Result<Task> createTask(const std::string& projectId, const TaskCreate& body,
                                           const std::string& idempotencyKey, std::stop_token stop = {}) const;
    // `mergePatch` is an RFC 7396 JSON Merge Patch: only changed fields, null clears a nullable field.
    [[nodiscard]] Result<Task> updateTask(const std::string& id, int version, const nlohmann::json& mergePatch,
                                           std::stop_token stop = {}) const;
    [[nodiscard]] Result<void> deleteTask(const std::string& id, int version, std::stop_token stop = {}) const;

private:
    [[nodiscard]] Result<HttpResponse> call(Method method, const std::string& path, Headers headers, std::string body,
                                             bool authenticated, std::stop_token stop) const;

    template <class T>
    [[nodiscard]] Result<T> fetch(Method method, const std::string& path, Headers headers, std::string body,
                                   bool authenticated, std::stop_token stop) const;

    Transport* transport_;  // not owned
    std::string baseUrl_;
    TokenProvider tokens_;
};

}  // namespace tt
