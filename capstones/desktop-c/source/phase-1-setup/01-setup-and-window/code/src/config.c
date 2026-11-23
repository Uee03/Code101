#include "config.h"

#include <stdlib.h>
#include <string.h>

#include "util.h"

static void from_env(char *dst, size_t cap, const char *name, const char *fallback) {
    const char *value = getenv(name);
    if (value != NULL && value[0] != '\0' && ts_copy(dst, cap, value)) return;
    ts_copy(dst, cap, fallback); /* the fallbacks are short literals and always fit */
}

static void trim_trailing_slashes(char *s) {
    size_t n = strlen(s);
    while (n > 0 && s[n - 1] == '/') s[--n] = '\0';
}

void ts_config_load(ts_config *cfg) {
    from_env(cfg->api_base, sizeof cfg->api_base, "TASKS_API_BASE", "http://localhost:8000");
    from_env(cfg->issuer, sizeof cfg->issuer, "TASKS_OIDC_ISSUER", "http://localhost:8180/realms/tasksteams");
    from_env(cfg->client_id, sizeof cfg->client_id, "TASKS_OIDC_CLIENT", TS_CLIENT_ID_DEFAULT);
    trim_trailing_slashes(cfg->api_base);
}
