#include "api/ApiClient.hpp"

#include <catch2/catch_test_macros.hpp>

#include <optional>
#include <stop_token>
#include <string>

namespace {

// Records the last request and answers with whatever `reply` holds.
class FakeTransport final : public tt::Transport {
public:
    tt::Result<tt::HttpResponse> send(const tt::HttpRequest& request, std::stop_token) override {
        last = request;
        return reply;
    }

    tt::HttpRequest last;
    tt::Result<tt::HttpResponse> reply{tt::HttpResponse{200, "{}", {}}};
};

std::string headerOf(const tt::HttpRequest& request, const std::string& name) {
    for (const auto& [key, value] : request.headers) {
        if (key == name) {
            return value;
        }
    }
    return {};
}

constexpr const char* kTaskJson =
    R"({"id":"t1","projectId":"p1","title":"Write","description":"","status":"todo","priority":"low",)"
    R"("assigneeId":null,"dueDate":null,"version":4,"updatedAt":"2026-01-01T00:00:00Z"})";

tt::ApiClient makeClient(FakeTransport& http) {
    return tt::ApiClient{http, "http://localhost:8000",
                         [](std::stop_token) { return tt::Result<std::string>(std::string{"tok"}); }};
}

}  // namespace

TEST_CASE("updateTask sends If-Match with the quoted version and a merge patch") {
    FakeTransport http;
    http.reply = tt::HttpResponse{200, kTaskJson, {}};
    const auto api = makeClient(http);
    nlohmann::json patch = nlohmann::json::object();
    patch["dueDate"] = nullptr;

    const auto result = api.updateTask("t1", 3, patch);

    REQUIRE(result.has_value());
    CHECK(result->version == 4);
    CHECK(http.last.method == tt::Method::Patch);
    CHECK(http.last.url == "http://localhost:8000/v1/tasks/t1");
    CHECK(headerOf(http.last, "If-Match") == "\"3\"");
    CHECK(headerOf(http.last, "Content-Type") == "application/merge-patch+json");
    CHECK(headerOf(http.last, "Authorization") == "Bearer tok");
    CHECK(http.last.body == R"({"dueDate":null})");
}

TEST_CASE("createTask sends the Idempotency-Key it was given") {
    FakeTransport http;
    http.reply = tt::HttpResponse{201, kTaskJson, {}};
    const auto api = makeClient(http);
    tt::TaskCreate body;
    body.title = "Write";

    const auto result = api.createTask("p1", body, "key-1234567890");

    REQUIRE(result.has_value());
    CHECK(http.last.method == tt::Method::Post);
    CHECK(headerOf(http.last, "Idempotency-Key") == "key-1234567890");
}

TEST_CASE("deleteTask sends If-Match") {
    FakeTransport http;
    http.reply = tt::HttpResponse{204, "", {}};
    const auto api = makeClient(http);

    const auto result = api.deleteTask("t1", 7);

    REQUIRE(result.has_value());
    CHECK(http.last.method == tt::Method::Delete);
    CHECK(headerOf(http.last, "If-Match") == "\"7\"");
}

TEST_CASE("listTasks repeats status, encodes the search text and copies the cursor") {
    FakeTransport http;
    http.reply = tt::HttpResponse{200, R"({"items":[],"page":{"limit":25,"nextCursor":null}})", {}};
    const auto api = makeClient(http);
    tt::TaskQuery query;
    query.statuses = {"todo", "blocked"};
    query.text = "a b";

    const auto page = api.listTasks("p1", query, std::optional<std::string>{"abc"});

    REQUIRE(page.has_value());
    CHECK_FALSE(page->nextCursor.has_value());
    CHECK(http.last.url ==
          "http://localhost:8000/v1/projects/p1/tasks?limit=25&sort=-createdAt&status=todo&status=blocked&q=a%20b&cursor=abc");
}

TEST_CASE("a 412 answer becomes a Problem with its RFC 9457 members") {
    FakeTransport http;
    http.reply = tt::HttpResponse{
        412,
        R"({"type":"https://code101.example/problems/precondition-failed","title":"Precondition failed",)"
        R"("status":412,"detail":"stale","traceId":"abc"})",
        {}};
    const auto api = makeClient(http);

    const auto result = api.updateTask("t1", 1, nlohmann::json::object());

    REQUIRE_FALSE(result.has_value());
    CHECK(result.error().kind == tt::ErrorKind::Http);
    CHECK(result.error().status == 412);
    CHECK(tt::problemSlug(result.error()) == "precondition-failed");
    CHECK(result.error().traceId == "abc");
}

TEST_CASE("a 429 answer keeps Retry-After") {
    FakeTransport http;
    tt::HttpResponse response{429, "{}", {}};
    response.headers.emplace("retry-after", "7");
    http.reply = response;
    const auto api = makeClient(http);

    const auto result = api.getTask("t1");

    REQUIRE_FALSE(result.has_value());
    CHECK(result.error().retryAfterSeconds == std::optional<int>{7});
}

TEST_CASE("an answer of the wrong shape is a Parse problem, not a crash") {
    FakeTransport http;
    http.reply = tt::HttpResponse{200, R"({"id":1})", {}};
    const auto api = makeClient(http);

    const auto result = api.getTask("t1");

    REQUIRE_FALSE(result.has_value());
    CHECK(result.error().kind == tt::ErrorKind::Parse);
}

TEST_CASE("a transport failure is passed on as a Network problem") {
    FakeTransport http;
    http.reply = tt::failure(tt::ErrorKind::Network, "down");
    const auto api = makeClient(http);

    const auto result = api.me();

    REQUIRE_FALSE(result.has_value());
    CHECK(result.error().kind == tt::ErrorKind::Network);
}
