#pragma once

#include "core/Result.hpp"

#include <array>
#include <optional>
#include <string>
#include <vector>

namespace tt {

inline constexpr std::array<const char*, 5> kStatuses{"todo", "in_progress", "blocked", "done", "cancelled"};
inline constexpr std::array<const char*, 4> kPriorities{"low", "medium", "high", "urgent"};

struct Health {
    std::string status;
    std::string database;
};

struct MeTeam {
    std::string teamId;
    std::string name;
    std::string role;
};

struct Me {
    std::string id;
    std::string username;
    std::string displayName;
    std::vector<std::string> roles;
    std::vector<std::string> scopes;
    std::vector<MeTeam> teams;
};

struct Team {
    std::string id;
    std::string name;
    std::string description;
    int memberCount{0};
    int version{0};
};

struct Project {
    std::string id;
    std::string teamId;
    std::string key;
    std::string name;
    bool archived{false};
    int version{0};
};

struct Task {
    std::string id;
    std::string projectId;
    std::string title;
    std::string description;
    std::string status;
    std::string priority;
    std::optional<std::string> assigneeId;
    std::optional<std::string> dueDate;
    int version{0};
    std::string updatedAt;
};

struct TaskCreate {
    std::string title;
    std::string description;
    std::string priority{"medium"};
    std::optional<std::string> dueDate;
};

template <class T>
struct Page {
    std::vector<T> items;
    std::optional<std::string> nextCursor;  // empty on the last page; opaque, never parse it
};

// nlohmann/json finds these through argument-dependent lookup when `.get<T>()` is called.
inline void from_json(const nlohmann::json& json, Health& health) {
    health.status = jsonString(json, "status");
    health.database = jsonString(json, "database");
}

inline void from_json(const nlohmann::json& json, MeTeam& team) {
    team.teamId = json.at("teamId").get<std::string>();
    team.name = json.at("name").get<std::string>();
    team.role = json.at("role").get<std::string>();
}

inline void from_json(const nlohmann::json& json, Me& me) {
    me.id = json.at("id").get<std::string>();
    me.username = json.at("username").get<std::string>();
    me.displayName = json.at("displayName").get<std::string>();
    me.roles = json.at("roles").get<std::vector<std::string>>();
    me.scopes = json.at("scopes").get<std::vector<std::string>>();
    me.teams = json.at("teams").get<std::vector<MeTeam>>();
}

inline void from_json(const nlohmann::json& json, Team& team) {
    team.id = json.at("id").get<std::string>();
    team.name = json.at("name").get<std::string>();
    team.description = jsonString(json, "description");
    team.memberCount = json.at("memberCount").get<int>();
    team.version = json.at("version").get<int>();
}

inline void from_json(const nlohmann::json& json, Project& project) {
    project.id = json.at("id").get<std::string>();
    project.teamId = json.at("teamId").get<std::string>();
    project.key = json.at("key").get<std::string>();
    project.name = json.at("name").get<std::string>();
    project.archived = json.at("archived").get<bool>();
    project.version = json.at("version").get<int>();
}

inline void from_json(const nlohmann::json& json, Task& task) {
    task.id = json.at("id").get<std::string>();
    task.projectId = json.at("projectId").get<std::string>();
    task.title = json.at("title").get<std::string>();
    task.description = jsonString(json, "description");
    task.status = json.at("status").get<std::string>();
    task.priority = json.at("priority").get<std::string>();
    task.assigneeId = jsonOptString(json, "assigneeId");
    task.dueDate = jsonOptString(json, "dueDate");
    task.version = json.at("version").get<int>();
    task.updatedAt = jsonString(json, "updatedAt");
}

template <class T>
void from_json(const nlohmann::json& json, Page<T>& page) {
    page.items = json.at("items").get<std::vector<T>>();
    page.nextCursor = jsonOptString(json.at("page"), "nextCursor");
}

[[nodiscard]] inline nlohmann::json toJson(const TaskCreate& task) {
    nlohmann::json json = nlohmann::json::object();
    json["title"] = task.title;
    json["description"] = task.description;
    json["priority"] = task.priority;
    if (task.dueDate) {
        json["dueDate"] = *task.dueDate;
    }
    return json;
}

// A bad UTF-8 byte is replaced instead of throwing from dump().
[[nodiscard]] inline std::string dumpJson(const nlohmann::json& json) {
    return json.dump(-1, ' ', false, nlohmann::json::error_handler_t::replace);
}

// Parses a body into T. Any missing or mistyped field becomes a Parse problem.
template <class T>
[[nodiscard]] Result<T> decode(const std::string& body) {
    try {
        return nlohmann::json::parse(body).get<T>();
    } catch (const nlohmann::json::exception& error) {
        return failure(ErrorKind::Parse, "The server answer was not understood", error.what());
    }
}

}  // namespace tt
