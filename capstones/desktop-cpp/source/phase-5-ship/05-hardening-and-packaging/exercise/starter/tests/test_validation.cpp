#include "core/Validation.hpp"

#include <catch2/catch_test_macros.hpp>

TEST_CASE("isValidDueDate accepts empty and real calendar dates") {
    CHECK(tt::isValidDueDate(""));
    CHECK(tt::isValidDueDate("2026-12-01"));
    CHECK(tt::isValidDueDate("2028-02-29"));  // 2028 is a leap year
}

TEST_CASE("isValidDueDate rejects shapes and dates that do not exist") {
    CHECK_FALSE(tt::isValidDueDate("2026-02-29"));  // 2026 is not a leap year
    CHECK_FALSE(tt::isValidDueDate("2026-13-01"));
    CHECK_FALSE(tt::isValidDueDate("2026-00-10"));
    CHECK_FALSE(tt::isValidDueDate("2026-12-32"));
    CHECK_FALSE(tt::isValidDueDate("2026/12/01"));
    CHECK_FALSE(tt::isValidDueDate("12/01/2026"));
    CHECK_FALSE(tt::isValidDueDate("2026-1-01"));
    CHECK_FALSE(tt::isValidDueDate("abcd-ef-gh"));
}

TEST_CASE("validateTask reports a bad due date next to the field") {
    const auto errors = tt::validateTask("title", "", "2026-13-45");
    REQUIRE(errors.size() == 1);
    CHECK(errors.front().pointer == "/dueDate");
}
