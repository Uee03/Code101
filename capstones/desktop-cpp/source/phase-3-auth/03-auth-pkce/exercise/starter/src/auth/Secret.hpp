#pragma once

#include <openssl/crypto.h>

#include <string>
#include <utility>

namespace tt {

// Exercise: make accidental logging safe.
// Rung 1 (guided): add `[[nodiscard]] std::string redacted() const` that returns "<empty>" for an empty
//   secret and "<secret, N characters>" otherwise (N is the length). It must never contain the value.
// Rung 2 (partial): use it in a log line in Session::signIn, for example spdlog::debug("token {}", ...).
// Rung 3 (open): why is "<secret, N characters>" still a small information leak? Write down one sentence.
class Secret {
public:
    Secret() = default;
    explicit Secret(std::string value) : value_{std::move(value)} {}
    Secret(const Secret&) = delete;
    Secret& operator=(const Secret&) = delete;
    Secret(Secret&& other) noexcept : value_{std::exchange(other.value_, std::string{})} {}
    Secret& operator=(Secret&& other) noexcept {
        if (this != &other) {
            wipe();
            value_ = std::exchange(other.value_, std::string{});
        }
        return *this;
    }
    ~Secret() { wipe(); }

    [[nodiscard]] const std::string& reveal() const noexcept { return value_; }
    [[nodiscard]] bool empty() const noexcept { return value_.empty(); }

    // TODO rung 1: redacted()

private:
    void wipe() noexcept {
        if (!value_.empty()) {
            OPENSSL_cleanse(value_.data(), value_.size());
        }
        value_.clear();
    }

    std::string value_;
};

}  // namespace tt
