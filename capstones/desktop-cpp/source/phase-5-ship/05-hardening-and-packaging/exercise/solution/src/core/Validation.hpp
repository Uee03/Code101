#pragma once

#include "core/Result.hpp"

#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

namespace tt {

inline constexpr std::size_t kMaxTitleChars = 200;
inline constexpr std::size_t kMaxDescriptionChars = 10'000;

// The number of Unicode characters in UTF-8 text: every byte that is not a continuation byte (10xxxxxx) starts one.
// The contract counts characters, so 200 letters with accents are fine even though they take 400 bytes.
[[nodiscard]] inline std::size_t utf8Length(std::string_view text) {
    std::size_t count = 0;
    for (const unsigned char c : text) {
        if ((c & 0xC0U) != 0x80U) {
            ++count;
        }
    }
    return count;
}

[[nodiscard]] inline bool isBlank(std::string_view text) {
    return text.find_first_not_of(" \t\r\n") == std::string_view::npos;
}

// Empty means "no due date". Otherwise YYYY-MM-DD with a real calendar date (leap years included).
[[nodiscard]] inline bool isValidDueDate(std::string_view text) {
    if (text.empty()) {
        return true;
    }
    if (text.size() != 10 || text[4] != '-' || text[7] != '-') {
        return false;
    }
    const auto number = [&text](std::size_t from, std::size_t count) {
        int value = 0;
        for (std::size_t i = from; i < from + count; ++i) {
            if (text[i] < '0' || text[i] > '9') {
                return -1;
            }
            value = value * 10 + (text[i] - '0');
        }
        return value;
    };
    const int year = number(0, 4);
    const int month = number(5, 2);
    const int day = number(8, 2);
    if (year < 1 || month < 1 || month > 12 || day < 1) {
        return false;
    }
    static constexpr int kDays[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    const bool leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
    const int limit = (month == 2 && leap) ? 29 : kDays[month - 1];
    return day <= limit;
}

// The contract's limits as one list of field errors (JSON Pointers into the request body). The server still has the last word.
[[nodiscard]] inline std::vector<FieldError> validateTask(std::string_view title, std::string_view description,
                                                          std::string_view dueDate) {
    std::vector<FieldError> errors;
    if (isBlank(title)) {
        errors.push_back(FieldError{"/title", "Enter a title."});
    } else if (utf8Length(title) > kMaxTitleChars) {
        errors.push_back(FieldError{"/title", "Use at most 200 characters."});
    }
    if (utf8Length(description) > kMaxDescriptionChars) {
        errors.push_back(FieldError{"/description", "Use at most 10000 characters."});
    }
    if (!isValidDueDate(dueDate)) {
        errors.push_back(FieldError{"/dueDate", "Use the format YYYY-MM-DD."});
    }
    return errors;
}

}  // namespace tt
