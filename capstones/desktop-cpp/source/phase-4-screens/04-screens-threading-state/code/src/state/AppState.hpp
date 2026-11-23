#pragma once

#include "api/Models.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <iterator>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace tt {

enum class AuthPhase { SignedOut, SigningIn, SignedIn };
enum class LoadPhase { Idle, Loading, Ready, Failed };

inline constexpr std::array<const char*, 3> kSorts{"-createdAt", "createdAt", "dueDate"};

// A list that is loaded page by page. Every request gets an id from begin(); finish() applies an answer
// only when its id is still the newest, so a slow answer for an old filter can never overwrite a newer list.
template <class T>
struct PagedList {
    LoadPhase phase{LoadPhase::Idle};
    std::vector<T> items;
    std::optional<std::string> nextCursor;
    std::optional<Problem> error;
    std::uint64_t generation{0};

    // Starts a request and returns its id. A fresh load (`reset`) empties the list, "load more" keeps it.
    std::uint64_t begin(bool reset) {
        ++generation;
        phase = LoadPhase::Loading;
        error.reset();
        if (reset) {
            items.clear();
            nextCursor.reset();
        }
        return generation;
    }

    // Applies the answer of request `id`. Returns false when a newer request has started: the answer is dropped.
    bool finish(std::uint64_t id, Result<Page<T>> result) {
        if (id != generation) {
            return false;
        }
        if (!result) {
            phase = LoadPhase::Failed;
            error = std::move(result.error());
            return true;
        }
        items.insert(items.end(), std::make_move_iterator(result->items.begin()),
                     std::make_move_iterator(result->items.end()));
        nextCursor = std::move(result->nextCursor);
        phase = LoadPhase::Ready;
        return true;
    }

    // Empties the list and makes every answer that is still on its way stale.
    void clear() {
        ++generation;
        phase = LoadPhase::Idle;
        items.clear();
        nextCursor.reset();
        error.reset();
    }
};

// Copies text into a fixed buffer for Dear ImGui's InputText. The buffers below are large enough for the
// contract's limits even when every character takes four bytes, so a value from the server is never cut.
template <std::size_t N>
void copyInto(std::array<char, N>& buffer, const std::string& text) {
    buffer.fill('\0');
    std::copy_n(text.begin(), std::min(text.size(), N - 1), buffer.begin());
}

template <std::size_t N>
[[nodiscard]] int indexOf(const std::array<const char*, N>& values, const std::string& wanted) {
    for (std::size_t i = 0; i < N; ++i) {
        if (wanted == values[i]) {
            return static_cast<int>(i);
        }
    }
    return 0;
}

// The create and edit dialog. `original` is the task as the server sent it; the patch holds only what differs.
struct TaskForm {
    bool open{false};
    bool creating{true};
    bool saving{false};
    std::string taskId;
    int baseVersion{0};
    std::string idempotencyKey;  // made when the form opens, so every retry of one form carries the same key
    std::array<char, 801> title{};          // 200 characters, up to 4 bytes each, and the terminator
    std::array<char, 40'001> description{};  // 10000 characters
    std::array<char, 11> dueDate{};          // YYYY-MM-DD
    int status{0};
    int priority{1};
    Task original;
    std::vector<FieldError> errors;  // client-side and 422 answers, matched to fields by JSON Pointer

    [[nodiscard]] TaskCreate toCreate() const {
        TaskCreate task;
        task.title = title.data();
        task.description = description.data();
        task.priority = kPriorities[static_cast<std::size_t>(priority)];
        if (dueDate[0] != '\0') {
            task.dueDate = std::string{dueDate.data()};
        }
        return task;
    }

    // RFC 7396 JSON Merge Patch: absent members stay as they are, null clears.
    [[nodiscard]] nlohmann::json makePatch() const {
        nlohmann::json patch = nlohmann::json::object();
        if (const std::string value{title.data()}; value != original.title) {
            patch["title"] = value;
        }
        if (const std::string value{description.data()}; value != original.description) {
            patch["description"] = value;
        }
        if (const std::string value{kStatuses[static_cast<std::size_t>(status)]}; value != original.status) {
            patch["status"] = value;
        }
        if (const std::string value{kPriorities[static_cast<std::size_t>(priority)]}; value != original.priority) {
            patch["priority"] = value;
        }
        if (const std::string value{dueDate.data()}; value != original.dueDate.value_or("")) {
            patch["dueDate"] = value.empty() ? nlohmann::json(nullptr) : nlohmann::json(value);
        }
        return patch;
    }
};

// The user's edit that the server refused with 412, kept so that "Keep my change" can send it again.
struct Conflict {
    std::string taskId;
    std::string title;
    nlohmann::json patch;
};

// Plain data that the UI draws. Only the UI thread reads or writes it.
struct AppState {
    AuthPhase auth{AuthPhase::SignedOut};
    std::optional<Me> me;
    std::optional<Problem> notice;  // the last error, shown until dismissed

    PagedList<Team> teams;
    PagedList<Project> projects;
    PagedList<Task> tasks;
    std::string teamId;
    std::string projectId;

    std::array<bool, kStatuses.size()> statusFilter{};
    std::array<char, 101> search{};
    int sortIndex{0};

    TaskForm form;
    std::optional<Conflict> conflict;
    std::optional<Task> pendingDelete;

    // Forgets everything that belongs to the signed-in user. The list generations keep counting up,
    // so answers that are still on their way are recognised as stale and dropped.
    void clearSession() {
        me.reset();
        teams.clear();
        projects.clear();
        tasks.clear();
        teamId.clear();
        projectId.clear();
        form = TaskForm{};
        conflict.reset();
        pendingDelete.reset();
    }
};

}  // namespace tt
