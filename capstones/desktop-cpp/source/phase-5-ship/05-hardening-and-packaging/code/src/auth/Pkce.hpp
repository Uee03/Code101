#pragma once

#include "core/Result.hpp"

#include <cstddef>
#include <span>
#include <string>
#include <string_view>

namespace tt {

struct Pkce {
    std::string verifier;   // secret, sent only to the token endpoint
    std::string challenge;  // BASE64URL(SHA-256(verifier)), sent in the browser URL
    std::string state;      // random, comes back unchanged in the redirect
};

// Base64url without padding (RFC 4648 section 5).
[[nodiscard]] std::string base64UrlEncode(std::span<const unsigned char> bytes);

// `byteCount` random bytes from OpenSSL's generator, base64url encoded.
[[nodiscard]] Result<std::string> randomToken(std::size_t byteCount);

// RFC 7636 S256 transform: BASE64URL(SHA-256(verifier)).
[[nodiscard]] Result<std::string> s256Challenge(std::string_view verifier);

[[nodiscard]] Result<Pkce> makePkce();

}  // namespace tt
