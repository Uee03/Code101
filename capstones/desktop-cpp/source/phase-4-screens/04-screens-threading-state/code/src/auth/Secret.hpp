#pragma once

#include <openssl/crypto.h>

#include <string>
#include <utility>

namespace tt {

// Holds a token. The bytes are overwritten when the object dies or is replaced.
// Best effort only: copies made by libcurl or the operating system are out of reach.
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
