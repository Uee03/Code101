#pragma once

#include "core/Result.hpp"

#include <string>

namespace tt {

// The friendly sentence for a problem. The technical members (status, type, trace id) are shown on a second line.
[[nodiscard]] inline std::string userMessage(const Problem& problem) {
    switch (problem.kind) {
        case ErrorKind::Network:
            return "Cannot reach the server. Check that the backend is running and that the address is right.";
        case ErrorKind::Parse:
            return "The server sent an answer this app does not understand.";
        case ErrorKind::Cancelled:
            return "Cancelled.";
        case ErrorKind::Auth:
        case ErrorKind::Config:
            return problem.title;
        case ErrorKind::Http:
            break;
    }
    const std::string slug = problemSlug(problem);
    if (slug == "unauthorized") {
        return "Your session has ended. Sign in again.";
    }
    if (slug == "forbidden") {
        return "You are not allowed to do this.";
    }
    if (slug == "not-found") {
        return "This item no longer exists, or you cannot see it.";
    }
    if (slug == "conflict") {
        return "This conflicts with existing data, for example a duplicate name.";
    }
    if (slug == "precondition-failed") {
        return "Someone else changed this item. Reload it and try again.";
    }
    if (slug == "precondition-required") {
        return "The app did not send the version it was editing. This is a bug; please report it.";
    }
    if (slug == "validation-error") {
        return "Some fields are not valid. See the messages next to them.";
    }
    if (slug == "bad-request") {
        return "The request was not valid. Reload the list and try again.";
    }
    if (slug == "rate-limited") {
        if (problem.retryAfterSeconds) {
            return "Too many requests. Try again in " + std::to_string(*problem.retryAfterSeconds) + " seconds.";
        }
        return "Too many requests. Try again in a moment.";
    }
    if (slug == "internal-error") {
        return "The server had a problem. Try again later and give the trace id to support.";
    }
    if (!problem.title.empty()) {
        return problem.title;
    }
    return "The request failed (status " + std::to_string(problem.status) + ").";
}

}  // namespace tt
