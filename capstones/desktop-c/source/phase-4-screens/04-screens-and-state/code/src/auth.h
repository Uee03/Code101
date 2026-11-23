#ifndef TS_AUTH_H
#define TS_AUTH_H

#include <SDL3/SDL.h>
#include <stdbool.h>
#include <stdint.h>

#include "config.h"
#include "loopback.h"
#include "model.h"
#include "pkce.h"

/* Sign-in state and the tokens. Tokens live only in two heap strings guarded by `lock`.
   Fields marked "sign-in" are touched by one thread at a time (worker in begin and finish, main in
   poll and cancel); the store's state machine guarantees they never overlap. */
typedef struct {
    ts_config cfg;
    SDL_Mutex *lock;         /* guards access, refresh, expires_at_ms, expired */
    SDL_Mutex *refresh_lock; /* held while a refresh request is in flight: one refresh at a time */
    char *access;
    char *refresh;
    uint64_t expires_at_ms;
    bool expired; /* a refresh was rejected: the session is over */

    char authorization_endpoint[320];
    char token_endpoint[320];
    char end_session_endpoint[320];
    bool have_endpoints;

    ts_pkce pkce;              /* sign-in */
    ts_loopback *lb;           /* sign-in */
    char redirect_uri[64];     /* sign-in */
} ts_auth;

typedef enum { TS_POLL_PENDING, TS_POLL_CODE, TS_POLL_FAILED } ts_poll_result;

bool ts_auth_init(ts_auth *a, const ts_config *cfg);
void ts_auth_free(ts_auth *a);

/* Worker thread. Discovers the endpoints, creates PKCE values, opens the loopback listener and writes
   the authorization URL into url. false: err says why and nothing is left open. */
bool ts_auth_begin(ts_auth *a, char *url, size_t url_cap, ts_problem *err);
/* Worker thread. Exchanges the code for tokens and stores them. */
bool ts_auth_finish(ts_auth *a, const char *code, ts_problem *err);

/* Main thread, every frame while waiting. On TS_POLL_CODE the code is in code. On TS_POLL_FAILED
   message says why and the sign-in is over. */
ts_poll_result ts_auth_poll(ts_auth *a, char *code, size_t code_cap, char *message, size_t message_cap);
void ts_auth_cancel(ts_auth *a); /* closes the listener and wipes the PKCE values */

/* Any thread. This is the ts_token_fn of the api: a new string the caller frees with ts_secure_free. */
char *ts_auth_token(void *ctx, bool force_refresh);
bool ts_auth_signed_in(ts_auth *a);
bool ts_auth_take_expired(ts_auth *a); /* true once after a rejected refresh */

/* Wipes the access token and returns the refresh token (the caller owns it: ts_secure_free) or NULL. */
char *ts_auth_clear(ts_auth *a);
/* Worker thread. Best-effort back-channel logout at Keycloak. Does not free refresh_token. */
void ts_auth_revoke(ts_auth *a, const char *refresh_token);

#endif
