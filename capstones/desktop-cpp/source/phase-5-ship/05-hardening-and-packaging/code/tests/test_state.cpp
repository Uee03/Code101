#include "core/ProblemText.hpp"
#include "core/Validation.hpp"
#include "state/AppState.hpp"

#include <catch2/catch_test_macros.hpp>

#include <string>

namespace {

tt::Result<tt::Page<tt::Team>> pageWith(const char* id, const char* nextCursor = nullptr) {
    tt::Page<tt::Team> page;
    page.items.push_back(tt::Team{id, "name", "", 1, 1});
    if (nextCursor != nullptr) {
        page.nextCursor = std::string{nextCursor};
    }
    return page;
}

}  // namespace

TEST_CASE("an answer for a superseded request is dropped") {
    tt::PagedList<tt::Team> list;
    const auto first = list.begin(true);
    const auto second = list.begin(true);

    CHECK_FALSE(list.finish(first, pageWith("old")));
    CHECK(list.items.empty());
    CHECK(list.finish(second, pageWith("new")));
    REQUIRE(list.items.size() == 1);
    CHECK(list.items.front().id == "new");
    CHECK(list.phase == tt::LoadPhase::Ready);
}

TEST_CASE("load more appends, a fresh load starts again, clear makes answers stale") {
    tt::PagedList<tt::Team> list;
    REQUIRE(list.finish(list.begin(true), pageWith("a", "cursor-1")));
    REQUIRE(list.nextCursor.has_value());

    REQUIRE(list.finish(list.begin(false), pageWith("b")));
    CHECK(list.items.size() == 2);
    CHECK_FALSE(list.nextCursor.has_value());

    const auto inFlight = list.begin(true);
    list.clear();
    CHECK_FALSE(list.finish(inFlight, pageWith("late")));
    CHECK(list.items.empty());
}

TEST_CASE("a failed request is kept as the list's error") {
    tt::PagedList<tt::Team> list;
    const auto id = list.begin(true);

    REQUIRE(list.finish(id, tt::failure(tt::ErrorKind::Network, "down")));

    CHECK(list.phase == tt::LoadPhase::Failed);
    REQUIRE(list.error.has_value());
    CHECK(list.error->kind == tt::ErrorKind::Network);
}

TEST_CASE("makePatch holds only changed fields and null clears the due date") {
    tt::TaskForm form;
    form.original.title = "Write";
    form.original.status = "todo";
    form.original.priority = "medium";
    form.original.dueDate = "2026-12-01";
    tt::copyInto(form.title, "Write");
    tt::copyInto(form.dueDate, "2026-12-01");
    form.status = 0;    // todo
    form.priority = 1;  // medium
    CHECK(form.makePatch().empty());

    tt::copyInto(form.title, "Write more");
    CHECK(form.makePatch().size() == 1);
    CHECK(form.makePatch().at("title") == "Write more");

    tt::copyInto(form.dueDate, "");
    const auto patch = form.makePatch();
    REQUIRE(patch.contains("dueDate"));
    CHECK(patch.at("dueDate").is_null());
}

TEST_CASE("userMessage chooses by problem type and falls back to the title") {
    tt::Problem problem;
    problem.kind = tt::ErrorKind::Http;
    problem.status = 412;
    problem.title = "Something else";
    problem.type = "https://code101.example/problems/precondition-failed";
    CHECK(tt::userMessage(problem) == "Someone else changed this item. Reload it and try again.");

    problem.type = "https://code101.example/problems/new-kind-of-problem";
    CHECK(tt::userMessage(problem) == "Something else");

    problem.type = "https://code101.example/problems/rate-limited";
    problem.retryAfterSeconds = 7;
    CHECK(tt::userMessage(problem) == "Too many requests. Try again in 7 seconds.");
}

TEST_CASE("validateTask counts characters, not bytes") {
    CHECK(tt::validateTask("", "", "").size() == 1);
    CHECK(tt::validateTask("   ", "", "").size() == 1);
    CHECK(tt::validateTask(std::string(200, 'a'), "", "").empty());
    CHECK(tt::validateTask(std::string(201, 'a'), "", "").size() == 1);

    std::string accents;
    for (int i = 0; i < 200; ++i) {
        accents += "\xC3\xA9";  // 200 characters, 400 bytes
    }
    CHECK(tt::validateTask(accents, "", "").empty());
    CHECK(tt::validateTask("title", std::string(10'001, 'a'), "").size() == 1);
    CHECK(tt::validateTask("title", "", "2026-12-01").empty());
    CHECK(tt::validateTask("title", "", "2026-1").size() == 1);
}
