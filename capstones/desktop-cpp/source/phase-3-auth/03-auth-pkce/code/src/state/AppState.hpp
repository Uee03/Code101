#pragma once

#include "api/Models.hpp"

#include <optional>

namespace tt {

enum class AuthPhase { SignedOut, SigningIn, SignedIn };

// Plain data that the UI draws. Only the UI thread reads or writes it.
struct AppState {
    AuthPhase auth{AuthPhase::SignedOut};
    std::optional<Me> me;
    std::optional<Problem> notice;  // the last error, shown until dismissed

    void clearSession() { me.reset(); }
};

}  // namespace tt
