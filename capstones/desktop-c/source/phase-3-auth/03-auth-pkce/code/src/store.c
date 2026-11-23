#include "store.h"

#include <string.h>

#include "http.h"

typedef enum { OP_HEALTH, OP_ME, OP_SIGN_BEGIN, OP_SIGN_FINISH, OP_SIGN_OUT } ts_op_kind;

/* One job's inputs and outputs. Allocated on the main thread, filled by the worker,
   read by done on the main thread, freed by release. */
typedef struct {
    ts_store *st;
    ts_op_kind kind;
    bool ok;
    ts_problem problem;
    ts_health health;
    ts_me me;
    char url[1024];  /* OP_SIGN_BEGIN output */
    char code[512];  /* OP_SIGN_FINISH input: the authorization code */
    char *secret;    /* OP_SIGN_OUT input: owns the old refresh token, wiped in release */
} ts_op;

static void op_run(void *ctx) {
    ts_op *op = ctx; /* worker thread: touches only op, the read-only api and the locked tokens */
    ts_store *st = op->st;
    switch (op->kind) {
    case OP_HEALTH:
        op->ok = ts_api_health(&st->api, &op->health, &op->problem);
        break;
    case OP_ME:
        op->ok = ts_api_me(&st->api, &op->me, &op->problem);
        break;
    case OP_SIGN_BEGIN:
        op->ok = ts_auth_begin(&st->auth, op->url, sizeof op->url, &op->problem);
        break;
    case OP_SIGN_FINISH:
        op->ok = ts_auth_finish(&st->auth, op->code, &op->problem) && ts_api_me(&st->api, &op->me, &op->problem);
        break;
    case OP_SIGN_OUT:
        ts_auth_revoke(&st->auth, op->secret);
        op->ok = true;
        break;
    }
}

static void show_problem(ts_store *st, const ts_problem *p) {
    st->problem = *p;
    st->has_problem = true;
    ts_problem_message(p, st->message, sizeof st->message);
}

static void op_done(void *ctx, void *user) {
    ts_op *op = ctx; /* main thread */
    ts_store *st = user;

    switch (op->kind) {
    case OP_SIGN_BEGIN:
        if (op->ok && ts_http_url_allowed(op->url) && SDL_OpenURL(op->url)) {
            ts_copy(st->sign_in_url, sizeof st->sign_in_url, op->url);
            st->auth_state = TS_AUTH_WAITING;
        } else {
            ts_auth_cancel(&st->auth);
            st->auth_state = TS_AUTH_SIGNED_OUT;
            if (op->ok) {
                ts_copy(st->login_message, sizeof st->login_message, "The browser could not be opened.");
            } else {
                ts_problem_message(&op->problem, st->login_message, sizeof st->login_message);
            }
        }
        return;
    case OP_SIGN_FINISH:
        if (op->ok) {
            st->me = op->me;
            st->have_me = true;
            st->auth_state = TS_AUTH_SIGNED_IN;
            st->login_message[0] = '\0';
        } else {
            ts_secure_free(ts_auth_clear(&st->auth)); /* tokens without a working /v1/me are useless */
            st->auth_state = TS_AUTH_SIGNED_OUT;
            ts_problem_message(&op->problem, st->login_message, sizeof st->login_message);
        }
        return;
    case OP_SIGN_OUT:
        return;
    case OP_HEALTH:
    case OP_ME:
        break;
    }

    if (!op->ok) {
        show_problem(st, &op->problem);
        return;
    }
    st->has_problem = false;
    if (op->kind == OP_HEALTH) {
        st->health = op->health;
        st->have_health = true;
    } else {
        ts_setf(st->info, sizeof st->info, "The API says you are %s (roles: %s).", op->me.display_name, op->me.roles);
    }
}

static void op_release(void *ctx) {
    ts_op *op = ctx;
    ts_secure_free(op->secret);
    ts_secure_zero(op, sizeof *op); /* an op may carry a code or a token: wipe before freeing */
    ts_free(op);
}

/* Takes ownership of secret (may be NULL) only when it returns true. */
static bool submit(ts_store *st, ts_op_kind kind, const char *code, char *secret) {
    ts_op *op = ts_calloc(1, sizeof *op);
    if (op == NULL) return false;
    op->st = st;
    op->kind = kind;
    if (code != NULL && !ts_copy(op->code, sizeof op->code, code)) {
        op_release(op);
        return false;
    }
    op->secret = secret;
    ts_job job = {.run = op_run, .done = op_done, .release = op_release, .ctx = op};
    if (!ts_jobs_submit(&st->jobs, job)) {
        op->secret = NULL; /* the caller keeps its secret */
        op_release(op);
        ts_problem busy;
        ts_problem_transport(&busy, "Too many requests are waiting. Try again in a moment.");
        show_problem(st, &busy);
        return false;
    }
    return true;
}

bool ts_store_init(ts_store *st) {
    memset(st, 0, sizeof *st);
    ts_config_load(&st->cfg);
    if (!ts_http_global_init()) return false;
    if (!ts_auth_init(&st->auth, &st->cfg)) {
        ts_http_global_cleanup();
        return false;
    }
    st->api.base = st->cfg.api_base;
    st->api.token = ts_auth_token;
    st->api.token_ctx = &st->auth;
    if (!ts_jobs_start(&st->jobs, st)) {
        ts_auth_free(&st->auth);
        ts_http_global_cleanup();
        return false;
    }
    return true;
}

void ts_store_pump(ts_store *st) {
    st->frames++;
    ts_jobs_pump(&st->jobs);

    if (st->auth_state == TS_AUTH_WAITING) {
        char code[512];
        ts_poll_result r = ts_auth_poll(&st->auth, code, sizeof code, st->login_message, sizeof st->login_message);
        if (r == TS_POLL_CODE) {
            st->auth_state = TS_AUTH_EXCHANGING;
            if (!submit(st, OP_SIGN_FINISH, code, NULL)) {
                ts_auth_cancel(&st->auth);
                st->auth_state = TS_AUTH_SIGNED_OUT;
                ts_copy(st->login_message, sizeof st->login_message, "Could not start the token request.");
            }
        } else if (r == TS_POLL_FAILED) {
            st->auth_state = TS_AUTH_SIGNED_OUT;
        }
        ts_secure_zero(code, sizeof code);
    }
    if (st->auth_state == TS_AUTH_SIGNED_IN && ts_auth_take_expired(&st->auth)) {
        st->auth_state = TS_AUTH_SIGNED_OUT;
        st->have_me = false;
        ts_copy(st->login_message, sizeof st->login_message, "Your session expired. Sign in again.");
    }
}

void ts_store_shutdown(ts_store *st) {
    ts_http_cancel_all(); /* a running transfer stops at once */
    ts_jobs_stop(&st->jobs);
    ts_auth_free(&st->auth);
    ts_http_global_cleanup();
}

bool ts_store_busy(ts_store *st) {
    return ts_jobs_in_flight(&st->jobs) > 0;
}

bool ts_store_check_health(ts_store *st) {
    return submit(st, OP_HEALTH, NULL, NULL);
}

bool ts_store_call_me(ts_store *st) {
    return submit(st, OP_ME, NULL, NULL);
}

void ts_store_dismiss_problem(ts_store *st) {
    st->has_problem = false;
}

bool ts_store_sign_in(ts_store *st) {
    if (st->auth_state != TS_AUTH_SIGNED_OUT) return false;
    st->login_message[0] = '\0';
    st->auth_state = TS_AUTH_STARTING;
    if (!submit(st, OP_SIGN_BEGIN, NULL, NULL)) {
        st->auth_state = TS_AUTH_SIGNED_OUT;
        return false;
    }
    return true;
}

void ts_store_cancel_sign_in(ts_store *st) {
    if (st->auth_state != TS_AUTH_WAITING) return; /* only then is the main thread the sole user of auth.lb */
    ts_auth_cancel(&st->auth);
    st->auth_state = TS_AUTH_SIGNED_OUT;
    ts_copy(st->login_message, sizeof st->login_message, "Sign-in cancelled.");
}

void ts_store_sign_out(ts_store *st) {
    if (st->auth_state != TS_AUTH_SIGNED_IN) return;
    char *refresh = ts_auth_clear(&st->auth); /* the local session ends now, whatever the network does */
    st->auth_state = TS_AUTH_SIGNED_OUT;
    st->have_me = false;
    st->info[0] = '\0';
    st->login_message[0] = '\0';
    if (refresh != NULL && !submit(st, OP_SIGN_OUT, NULL, refresh)) ts_secure_free(refresh);
}
