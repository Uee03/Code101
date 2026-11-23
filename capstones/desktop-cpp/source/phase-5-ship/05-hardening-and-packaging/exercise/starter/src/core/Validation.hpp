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

// Exercise. Empty means "no due date". Today this only checks the length, so "2026-13-45" passes.
// Rung 1 (guided): run the tests in tests/test_validation.cpp and read which checks fail.
// Rung 2 (partial): require digits at the right places and dashes at index 4 and 7.
// Rung 3 (open): reject months outside 1 to 12 and days outside the month, including 29 February only in leap years.
[[nodiscard]] inline bool isValidDueDate(std::string_view text) { return text.empty() || text.size() == 10; }

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
