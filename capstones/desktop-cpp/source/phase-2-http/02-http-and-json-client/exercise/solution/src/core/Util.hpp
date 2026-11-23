#pragma once

#include <cstdlib>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace tt {

// RFC 3986: letters, digits and - . _ ~ stay; every other byte becomes %XX.
[[nodiscard]] inline std::string urlEncode(std::string_view text) {
    static constexpr char kHex[] = "0123456789ABCDEF";
    std::string out;
    out.reserve(text.size());
    for (const unsigned char c : text) {
        const bool unreserved = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') ||
                                c == '-' || c == '.' || c == '_' || c == '~';
        if (unreserved) {
            out.push_back(static_cast<char>(c));
        } else {
            out.push_back('%');
            out.push_back(kHex[c >> 4]);
            out.push_back(kHex[c & 0x0F]);
        }
    }
    return out;
}

// Builds "a=1&b=2" with every name and value encoded. Used for query strings and form bodies.
class QueryBuilder {
public:
    QueryBuilder& add(std::string_view name, std::string_view value) {
        if (!text_.empty()) {
            text_.push_back('&');
        }
        text_ += urlEncode(name);
        text_.push_back('=');
        text_ += urlEncode(value);
        return *this;
    }

    // Repeats the parameter once per value: addAll("status", {"todo", "done"}) gives status=todo&status=done.
    QueryBuilder& addAll(std::string_view name, const std::vector<std::string>& values) {
        for (const auto& value : values) {
            add(name, value);
        }
        return *this;
    }

    // Adds the parameter only when the optional holds a value.
    QueryBuilder& addIf(std::string_view name, const std::optional<std::string>& value) {
        if (value) {
            add(name, *value);
        }
        return *this;
    }

    [[nodiscard]] const std::string& str() const noexcept { return text_; }
    [[nodiscard]] bool empty() const noexcept { return text_.empty(); }

private:
    std::string text_;
};

// The value of an environment variable, or `fallback` when it is unset or empty.
[[nodiscard]] inline std::string envOr(const char* name, std::string fallback) {
#ifdef _MSC_VER
    char* raw = nullptr;
    std::size_t size = 0;
    if (_dupenv_s(&raw, &size, name) != 0 || raw == nullptr) {
        return fallback;
    }
    const std::unique_ptr<char, decltype(&std::free)> holder{raw, &std::free};
    return *holder != '\0' ? std::string{holder.get()} : fallback;
#else
    const char* value = std::getenv(name);
    return (value != nullptr && *value != '\0') ? std::string{value} : fallback;
#endif
}

}  // namespace tt
