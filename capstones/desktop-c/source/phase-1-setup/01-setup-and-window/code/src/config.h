#ifndef TS_CONFIG_H
#define TS_CONFIG_H

/* The client id and scopes are fixed by the Keycloak client in keycloak/tasks-desktop-client.json. */
#define TS_CLIENT_ID_DEFAULT "tasks-desktop"
#define TS_SCOPES "openid profile email tasks:read tasks:write"

typedef struct {
    char api_base[256];
    char issuer[256];
    char client_id[64];
} ts_config;

/* Fills cfg from the environment. A missing or too-long value falls back to the default. */
void ts_config_load(ts_config *cfg);

#endif
