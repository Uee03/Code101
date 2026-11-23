#include "auth/Pkce.hpp"
#include "auth/Secret.hpp"

#include <catch2/catch_test_macros.hpp>

#include <string>
#include <string_view>
#include <utility>

namespace {

std::string encode(std::string_view text) {
    const auto* data = reinterpret_cast<const unsigned char*>(text.data());
    return tt::base64UrlEncode({data, text.size()});
}

}  // namespace

TEST_CASE("base64url has no padding and uses - and _ (RFC 4648 examples)") {
    CHECK(encode("").empty());
    CHECK(encode("f") == "Zg");
    CHECK(encode("fo") == "Zm8");
    CHECK(encode("foo") == "Zm9v");
    CHECK(encode("foobar") == "Zm9vYmFy");
    const unsigned char bytes[] = {0xFB, 0xFF};
    CHECK(tt::base64UrlEncode(bytes) == "-_8");
}

TEST_CASE("the S256 challenge matches the example of RFC 7636 appendix B") {
    const auto challenge = tt::s256Challenge("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk");
    REQUIRE(challenge.has_value());
    CHECK(*challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM");
}

TEST_CASE("makePkce gives a 43 character verifier, a matching challenge and a fresh state") {
    const auto first = tt::makePkce();
    const auto second = tt::makePkce();
    REQUIRE(first.has_value());
    REQUIRE(second.has_value());
    CHECK(first->verifier.size() == 43);
    CHECK(first->verifier != second->verifier);
    CHECK(first->state != second->state);
    CHECK(tt::s256Challenge(first->verifier).value() == first->challenge);
}

TEST_CASE("a moved Secret leaves nothing behind") {
    tt::Secret first{"token-value"};
    tt::Secret second{std::move(first)};
    CHECK(first.empty());
    CHECK(second.reveal() == "token-value");
}
