#include "auth.h"

#include <cjson/cJSON.h>
#include <string.h>

#include "http.h"
#include "util.h"

/* ---------------------------------------------------------------- setup */

bool ts_auth_init(ts_auth *a, const ts_config *cfg) {
    memset(a, 0, sizeof *a);
    a->cfg = *cfg;
    a->lock = SDL_CreateMutex();
    a->refresh_lock = SDL_CreateMutex();
    if (a->lock == NULL || a->refresh_lock == NULL) {
        if (a->lock != NULL) SDL_DestroyMutex(a->lock);
        if (a->refresh_lock != NULL) SDL_DestroyMutex(a->refresh_lock);
        memset(a, 0, sizeof *a);
        return false;
    }
    return true;
}

void ts_auth_cancel(ts_auth *a) {
    ts_loopback_close(a->lb);
    a->lb = NULL;
    ts_secure_zero(&a->pkce, sizeof a->pkce);
}

void ts_auth_free(ts_auth *a) {
    ts_auth_cancel(a);
    ts_secure_free(a->access);
    ts_secure_free(a->refresh);
    a->access = NULL;
    a->refresh = NULL;
    if (a->lock != NULL) SDL_DestroyMutex(a->lock);
    if (a->refresh_lock != NULL) SDL_DestroyMutex(a->refresh_lock);
    a->lock = NULL;
    a->refresh_lock = NULL;
}

/* ---------------------------------------------------------------- discovery */

static bool copy_endpoint(const cJSON *root, const char *key, char *dst, size_t cap) {
    const cJSON *v = cJSON_GetObjectItemCaseSensitive(root, key);
    if (!cJSON_IsString(v) || v->valuestring == NULL) return false;
    if (!ts_http_url_allowed(v->valuestring)) return false; /* the document is untrusted input */
    return ts_copy(dst, cap, v->valuestring);
}

static bool discover(ts_auth *a, ts_problem *err) {
    if (a->have_endpoints) return true;
    char url[400];
    if (!ts_setf(url, sizeof url, "%s/.well-known/openid-configuration", a->cfg.issuer)) {
        ts_problem_transport(err, "The issuer address is too long.");
        return false;
    }
    ts_http_response res;
    ts_http_response_init(&res);
    ts_http_request req = {.method = TS_HTTP_GET, .url = url};
    if (!ts_http_send(&req, &res)) {
        ts_problem_transport(err, res.error);
        ts_http_response_free(&res);
        return false;
    }
    if (res.status != 200) {
        ts_problem_parse(ts_buf_cstr(&res.body), res.body.len, res.status, res.content_type, res.retry_after_s, err);
        ts_http_response_free(&res);
        return false;
    }
    cJSON *root = cJSON_ParseWithLength(ts_buf_cstr(&res.body), res.body.len);
    const cJSON *issuer = cJSON_GetObjectItemCaseSensitive(root, "issuer");
    bool ok = cJSON_IsString(issuer) && issuer->valuestring != NULL && strcmp(issuer->valuestring, a->cfg.issuer) == 0 &&
              copy_endpoint(root, "authorization_endpoint", a->authorization_endpoint, sizeof a->authorization_endpoint) &&
              copy_endpoint(root, "token_endpoint", a->token_endpoint, sizeof a->token_endpoint) &&
              copy_endpoint(root, "end_session_endpoint", a->end_session_endpoint, sizeof a->end_session_endpoint);
    cJSON_Delete(root);
    ts_http_response_free(&res);
    if (!ok) {
        ts_problem_transport(err, "The identity server's discovery document is incomplete or its issuer does not match.");
        return false;
    }
    a->have_endpoints = true;
    return true;
}

/* ---------------------------------------------------------------- sign-in */

bool ts_auth_begin(ts_auth *a, char *url, size_t url_cap, ts_problem *err) {
    ts_auth_cancel(a); /* an earlier attempt, if any, is over */
    if (!discover(a, err)) return false;
    if (!ts_pkce_new(&a->pkce)) {
        ts_problem_transport(err, "The system could not provide random numbers.");
        return false;
    }
    int port = 0;
    a->lb = ts_loopback_open("/callback", &port);
    if (a->lb == NULL) {
        ts_auth_cancel(a);
        ts_problem_transport(err, "Could not open a local port for the sign-in answer.");
        return false;
    }
    if (!ts_setf(a->redirect_uri, sizeof a->redirect_uri, "http://127.0.0.1:%d/callback", port)) {
        ts_auth_cancel(a);
        ts_problem_transport(err, "Internal error: redirect address too long.");
        return false;
    }

    char *client = ts_url_encode(a->cfg.client_id);
    char *redirect = ts_url_encode(a->redirect_uri);
    char *scope = ts_url_encode(TS_SCOPES);
    bool ok = client != NULL && redirect != NULL && scope != NULL &&
              ts_setf(url, url_cap,
                      "%s?response_type=code&client_id=%s&redirect_uri=%s&scope=%s&state=%s"
                      "&code_challenge=%s&code_challenge_method=S256",
                      a->authorization_endpoint, client, redirect, scope, a->pkce.state, a->pkce.challenge);
    ts_free(client);
    ts_free(redirect);
    ts_free(scope);
    if (!ok || !ts_http_url_allowed(url)) {
        ts_auth_cancel(a);
        ts_problem_transport(err, "Could not build the sign-in address.");
        return false;
    }
    return true;
}

/* Finds key in a query string, percent-decodes its value into out. false when absent or too long. */
static bool query_get(const char *query, const char *key, char *out, size_t cap) {
    size_t key_len = strlen(key);
    out[0] = '\0';
    const char *p = query;
    while (*p != '\0') {
        const char *amp = strchr(p, '&');
        size_t len = amp != NULL ? (size_t)(amp - p) : strlen(p);
        if (len > key_len && p[key_len] == '=' && strncmp(p, key, key_len) == 0) {
            char tmp[512];
            size_t value_len = len - key_len - 1;
            if (value_len >= sizeof tmp) return false;
            memcpy(tmp, p + key_len + 1, value_len);
            tmp[value_len] = '\0';
            ts_url_decode(tmp);
            bool fits = ts_copy(out, cap, tmp);
            ts_secure_zero(tmp, sizeof tmp);
            return fits;
        }
        p += len;
        if (*p == '&') p++;
    }
    return false;
}

ts_poll_result ts_auth_poll(ts_auth *a, char *code, size_t code_cap, char *message, size_t message_cap) {
    if (a->lb == NULL) {
        ts_copy(message, message_cap, "No sign-in is waiting.");
        return TS_POLL_FAILED;
    }
    char query[1024];
    ts_lb_state s = ts_loopback_poll(a->lb, query, sizeof query);
    if (s == TS_LB_PENDING) return TS_POLL_PENDING;
    if (s == TS_LB_TIMEOUT) {
        ts_copy(message, message_cap, "Sign-in timed out after 3 minutes. Try again.");
        ts_auth_cancel(a);
        return TS_POLL_FAILED;
    }
    if (s == TS_LB_FAILED) {
        ts_copy(message, message_cap, "The browser's answer could not be read.");
        ts_auth_cancel(a);
        return TS_POLL_FAILED;
    }

    ts_loopback_close(a->lb); /* one answer only: the port is closed from now on */
    a->lb = NULL;

    char state[128], error[128];
    query_get(query, "state", state, sizeof state);
    if (query_get(query, "error", error, sizeof error)) {
        ts_setf(message, message_cap, "The identity server refused the sign-in: %s", error);
        ts_auth_cancel(a);
        return TS_POLL_FAILED;
    }
    if (state[0] == '\0' || !ts_secure_equal(state, a->pkce.state)) {
        ts_copy(message, message_cap, "The answer did not belong to this sign-in attempt (state mismatch). Nothing was sent.");
        ts_auth_cancel(a);
        return TS_POLL_FAILED;
    }
    if (!query_get(query, "code", code, code_cap) || code[0] == '\0') {
        ts_copy(message, message_cap, "The answer did not contain an authorization code.");
        ts_auth_cancel(a);
        return TS_POLL_FAILED;
    }
    return TS_POLL_CODE;
}

/* ---------------------------------------------------------------- tokens */

static bool form_add(ts_buf *b, const char *key, const char *value) {
    char *encoded = ts_url_encode(value);
    if (encoded == NULL) return false;
    bool ok = (b->len == 0 || ts_buf_appends(b, "&")) && ts_buf_appends(b, key) && ts_buf_appends(b, "=") &&
              ts_buf_appends(b, encoded);
    ts_secure_free(encoded); /* the value may be a refresh token */
    return ok;
}

static void store_tokens(ts_auth *a, char *access, char *refresh_or_null, long expires_in) {
    if (expires_in <= 0 || expires_in > 86400) expires_in = 300;
    SDL_LockMutex(a->lock);
    ts_secure_free(a->access);
    a->access = access; /* ownership moves into the auth object */
    if (refresh_or_null != NULL) {
        ts_secure_free(a->refresh);
        a->refresh = refresh_or_null;
    }
    a->expires_at_ms = ts_now_ms() + (uint64_t)expires_in * 1000u;
    a->expired = false;
    SDL_UnlockMutex(a->lock);
}

/* POSTs a token-endpoint form and stores the tokens. *rejected tells "the server said no"
   (as opposed to "the network failed"). */
static bool token_request(ts_auth *a, const ts_buf *form, ts_problem *err, bool *rejected) {
    *rejected = false;
    ts_http_response res;
    ts_http_response_init(&res);
    ts_http_request req = {.method = TS_HTTP_POST,
                           .url = a->token_endpoint,
                           .content_type = "application/x-www-form-urlencoded",
                           .body = form->data,
                           .body_len = form->len};
    if (!ts_http_send(&req, &res)) {
        ts_problem_transport(err, res.error);
        ts_http_response_free(&res);
        return false;
    }
    cJSON *root = cJSON_ParseWithLength(ts_buf_cstr(&res.body), res.body.len);
    if (res.status != 200) {
        *rejected = res.status == 400 || res.status == 401;
        ts_problem_clear(err);
        err->status = res.status;
        ts_copy(err->title, sizeof err->title, "The identity server refused the request");
        const cJSON *d = cJSON_GetObjectItemCaseSensitive(root, "error_description");
        const cJSON *e = cJSON_GetObjectItemCaseSensitive(root, "error");
        if (cJSON_IsString(d) && d->valuestring != NULL) {
            ts_copy(err->detail, sizeof err->detail, d->valuestring);
        } else if (cJSON_IsString(e) && e->valuestring != NULL) {
            ts_copy(err->detail, sizeof err->detail, e->valuestring);
        }
        cJSON_Delete(root);
        ts_buf_wipe(&res.body);
        ts_http_response_free(&res);
        return false;
    }

    const cJSON *at = cJSON_GetObjectItemCaseSensitive(root, "access_token");
    const cJSON *rt = cJSON_GetObjectItemCaseSensitive(root, "refresh_token");
    const cJSON *ei = cJSON_GetObjectItemCaseSensitive(root, "expires_in");
    const cJSON *tt = cJSON_GetObjectItemCaseSensitive(root, "token_type");
    bool valid = cJSON_IsString(at) && at->valuestring != NULL && at->valuestring[0] != '\0' && cJSON_IsString(tt) &&
                 tt->valuestring != NULL && SDL_strcasecmp(tt->valuestring, "Bearer") == 0;
    char *new_access = valid ? ts_strdup(at->valuestring) : NULL;
    char *new_refresh = (valid && cJSON_IsString(rt) && rt->valuestring != NULL) ? ts_strdup(rt->valuestring) : NULL;
    long expires_in = cJSON_IsNumber(ei) ? (long)ei->valuedouble : 0;
    cJSON_Delete(root);
    ts_buf_wipe(&res.body); /* the body held the tokens in clear text */
    ts_http_response_free(&res);

    if (new_access == NULL) {
        ts_secure_free(new_refresh);
        ts_problem_transport(err, "The token answer was incomplete.");
        return false;
    }
    store_tokens(a, new_access, new_refresh, expires_in); /* new_refresh may be NULL: keep the old one */
    return true;
}

bool ts_auth_finish(ts_auth *a, const char *code, ts_problem *err) {
    ts_buf form;
    ts_buf_init(&form);
    bool rejected = false;
    bool ok = a->pkce.verifier[0] != '\0' && form_add(&form, "grant_type", "authorization_code") &&
              form_add(&form, "code", code) && form_add(&form, "redirect_uri", a->redirect_uri) &&
              form_add(&form, "client_id", a->cfg.client_id) && form_add(&form, "code_verifier", a->pkce.verifier);
    if (!ok) {
        ts_problem_transport(err, "Could not build the token request.");
    } else {
        ok = token_request(a, &form, err, &rejected);
    }
    ts_buf_wipe(&form);
    ts_secure_zero(&a->pkce, sizeof a->pkce); /* the verifier is single use */
    return ok;
}

static void wipe_session(ts_auth *a) {
    char *rt = ts_auth_clear(a);
    ts_secure_free(rt);
}

static void refresh_tokens(ts_auth *a, const char *refresh_token) {
    ts_buf form;
    ts_buf_init(&form);
    bool rejected = false;
    ts_problem err;
    bool built = form_add(&form, "grant_type", "refresh_token") && form_add(&form, "refresh_token", refresh_token) &&
                 form_add(&form, "client_id", a->cfg.client_id);
    if (built && !token_request(a, &form, &err, &rejected) && rejected) {
        wipe_session(a);
        SDL_LockMutex(a->lock);
        a->expired = true; /* the user must sign in again; nothing else is lost */
        SDL_UnlockMutex(a->lock);
    }
    ts_buf_wipe(&form);
}

char *ts_auth_token(void *ctx, bool force_refresh) {
    ts_auth *a = ctx;
    SDL_LockMutex(a->refresh_lock); /* everybody waits here while one refresh runs: single flight */

    SDL_LockMutex(a->lock);
    bool due = a->refresh != NULL && (force_refresh || ts_now_ms() + 60000u >= a->expires_at_ms);
    char *refresh_copy = due ? ts_strdup(a->refresh) : NULL;
    SDL_UnlockMutex(a->lock);

    if (refresh_copy != NULL) refresh_tokens(a, refresh_copy);
    ts_secure_free(refresh_copy);

    SDL_LockMutex(a->lock);
    char *out = a->access != NULL ? ts_strdup(a->access) : NULL;
    SDL_UnlockMutex(a->lock);

    SDL_UnlockMutex(a->refresh_lock);
    return out;
}

bool ts_auth_signed_in(ts_auth *a) {
    SDL_LockMutex(a->lock);
    bool in = a->access != NULL;
    SDL_UnlockMutex(a->lock);
    return in;
}

bool ts_auth_take_expired(ts_auth *a) {
    SDL_LockMutex(a->lock);
    bool was = a->expired;
    a->expired = false;
    SDL_UnlockMutex(a->lock);
    return was;
}

char *ts_auth_clear(ts_auth *a) {
    SDL_LockMutex(a->lock);
    char *refresh = a->refresh; /* ownership moves to the caller */
    a->refresh = NULL;
    ts_secure_free(a->access);
    a->access = NULL;
    a->expires_at_ms = 0;
    SDL_UnlockMutex(a->lock);
    return refresh;
}

void ts_auth_revoke(ts_auth *a, const char *refresh_token) {
    if (refresh_token == NULL || !a->have_endpoints) return;
    ts_buf form;
    ts_buf_init(&form);
    if (form_add(&form, "client_id", a->cfg.client_id) && form_add(&form, "refresh_token", refresh_token)) {
        ts_http_response res;
        ts_http_response_init(&res);
        ts_http_request req = {.method = TS_HTTP_POST,
                               .url = a->end_session_endpoint,
                               .content_type = "application/x-www-form-urlencoded",
                               .body = form.data,
                               .body_len = form.len};
        ts_http_send(&req, &res); /* best effort: the local session is already gone */
        ts_http_response_free(&res);
    }
    ts_buf_wipe(&form);
}
