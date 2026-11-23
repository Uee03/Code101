#include "core/Config.hpp"

#include <catch2/catch_test_macros.hpp>

TEST_CASE("isAllowedUrl accepts https and loopback http only") {
    CHECK(tt::isAllowedUrl("https://api.example.com"));
    CHECK(tt::isAllowedUrl("https://api.example.com:8443/v1"));
    CHECK(tt::isAllowedUrl("http://localhost:8000"));
    CHECK(tt::isAllowedUrl("http://127.0.0.1:8180/realms/tasksteams"));
    CHECK(tt::isAllowedUrl("http://[::1]:8000"));

    CHECK_FALSE(tt::isAllowedUrl("http://api.example.com"));
    CHECK_FALSE(tt::isAllowedUrl("http://localhost.evil.example"));
    CHECK_FALSE(tt::isAllowedUrl("https://user:secret@api.example.com"));
    CHECK_FALSE(tt::isAllowedUrl("https://api.example.com/?debug=1"));
    CHECK_FALSE(tt::isAllowedUrl("https://api.example.com/#top"));
    CHECK_FALSE(tt::isAllowedUrl("ftp://localhost"));
    CHECK_FALSE(tt::isAllowedUrl("localhost:8000"));
    CHECK_FALSE(tt::isAllowedUrl("https://"));
    CHECK_FALSE(tt::isAllowedUrl(""));
}

TEST_CASE("withoutTrailingSlash removes every closing slash") {
    CHECK(tt::withoutTrailingSlash("http://localhost:8000/") == "http://localhost:8000");
    CHECK(tt::withoutTrailingSlash("http://localhost:8000") == "http://localhost:8000");
}
