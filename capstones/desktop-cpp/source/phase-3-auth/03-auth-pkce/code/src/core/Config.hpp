#pragma once

#include "core/Util.hpp"

#include <string>

namespace tt {

struct Config {
    std::string apiBaseUrl;
    std::string issuer;
    std::string clientId{"tasks-desktop"};
    std::string scope{"openid profile email tasks:read tasks:write"};
};

// Defaults match the platform: API on 8000, Keycloak realm tasksteams on 8180.
[[nodiscard]] inline Config loadConfig() {
    Config config;
    config.apiBaseUrl = envOr("API_BASE_URL", "http://localhost:8000");
    config.issuer = envOr("OIDC_ISSUER", "http://localhost:8180/realms/tasksteams");
    return config;
}

}  // namespace tt
