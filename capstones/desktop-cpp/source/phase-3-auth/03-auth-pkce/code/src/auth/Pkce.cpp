#include "auth/Pkce.hpp"

#include <openssl/evp.h>
#include <openssl/rand.h>

#include <array>
#include <vector>

namespace tt {

std::string base64UrlEncode(std::span<const unsigned char> bytes) {
    static constexpr char kAlphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    std::string out;
    out.reserve((bytes.size() * 4 + 2) / 3);
    std::size_t i = 0;
    for (; i + 3 <= bytes.size(); i += 3) {
        const unsigned value = (static_cast<unsigned>(bytes[i]) << 16) | (static_cast<unsigned>(bytes[i + 1]) << 8) |
                               static_cast<unsigned>(bytes[i + 2]);
        out.push_back(kAlphabet[(value >> 18) & 63U]);
        out.push_back(kAlphabet[(value >> 12) & 63U]);
        out.push_back(kAlphabet[(value >> 6) & 63U]);
        out.push_back(kAlphabet[value & 63U]);
    }
    const std::size_t rest = bytes.size() - i;
    if (rest == 1) {
        const unsigned value = static_cast<unsigned>(bytes[i]) << 16;
        out.push_back(kAlphabet[(value >> 18) & 63U]);
        out.push_back(kAlphabet[(value >> 12) & 63U]);
    } else if (rest == 2) {
        const unsigned value = (static_cast<unsigned>(bytes[i]) << 16) | (static_cast<unsigned>(bytes[i + 1]) << 8);
        out.push_back(kAlphabet[(value >> 18) & 63U]);
        out.push_back(kAlphabet[(value >> 12) & 63U]);
        out.push_back(kAlphabet[(value >> 6) & 63U]);
    }
    return out;
}

Result<std::string> randomToken(std::size_t byteCount) {
    std::vector<unsigned char> bytes(byteCount);
    if (RAND_bytes(bytes.data(), static_cast<int>(bytes.size())) != 1) {
        return failure(ErrorKind::Auth, "No secure random numbers available");
    }
    return base64UrlEncode(bytes);
}

Result<std::string> s256Challenge(std::string_view verifier) {
    std::array<unsigned char, EVP_MAX_MD_SIZE> digest{};
    unsigned int length = 0;
    if (EVP_Digest(verifier.data(), verifier.size(), digest.data(), &length, EVP_sha256(), nullptr) != 1) {
        return failure(ErrorKind::Auth, "Cannot compute the PKCE challenge");
    }
    return base64UrlEncode(std::span<const unsigned char>{digest.data(), length});
}

Result<Pkce> makePkce() {
    auto verifier = randomToken(32);
    if (!verifier) {
        return tl::make_unexpected(std::move(verifier.error()));
    }
    auto state = randomToken(16);
    if (!state) {
        return tl::make_unexpected(std::move(state.error()));
    }
    auto challenge = s256Challenge(*verifier);
    if (!challenge) {
        return tl::make_unexpected(std::move(challenge.error()));
    }
    return Pkce{std::move(*verifier), std::move(*challenge), std::move(*state)};
}

}  // namespace tt
