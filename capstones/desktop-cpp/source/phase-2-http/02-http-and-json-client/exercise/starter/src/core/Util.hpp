#pragma once

#include <cstdlib>
#include <memory>
#include <string>
#include <string_view>

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
// Exercise: rung 1 add addAll(name, values) that repeats a parameter, rung 2 add addIf(name, optional)
// that adds only when the optional holds a value, rung 3 use both in ApiClient::listTasks.
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

    // TODO rung 1: QueryBuilder& addAll(std::string_view name, const std::vector<std::string>& values)
    // TODO rung 2: QueryBuilder& addIf(std::string_view name, const std::optional<std::string>& value)

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
