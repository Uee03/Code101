#include "store.h"

#include <string.h>

#include "http.h"

typedef enum { OP_HEALTH, OP_ME } ts_op_kind;

/* One job's inputs and outputs. Allocated on the main thread, filled by the worker,
   read by done on the main thread, freed by release. */
typedef struct {
    ts_store *st;
    ts_op_kind kind;
    bool ok;
    ts_problem problem;
    ts_health health;
    ts_me me;
} ts_op;

static void op_run(void *ctx) {
    ts_op *op = ctx; /* worker thread: touches only op and the read-only api */
    const ts_api *api = &op->st->api;
    switch (op->kind) {
    case OP_HEALTH:
        op->ok = ts_api_health(api, &op->health, &op->problem);
        break;
    case OP_ME:
        op->ok = ts_api_me(api, &op->me, &op->problem);
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
    if (!op->ok) {
        show_problem(st, &op->problem);
        return;
    }
    st->has_problem = false;
    switch (op->kind) {
    case OP_HEALTH:
        st->health = op->health;
        st->have_health = true;
        break;
    case OP_ME:
        ts_setf(st->message, sizeof st->message, "Signed in as %s", op->me.display_name);
        break;
    }
}

static void op_release(void *ctx) {
    ts_secure_zero(ctx, sizeof(ts_op)); /* an op may carry user data: wipe before freeing */
    ts_free(ctx);
}

static bool submit(ts_store *st, ts_op_kind kind) {
    ts_op *op = ts_calloc(1, sizeof *op);
    if (op == NULL) return false;
    op->st = st;
    op->kind = kind;
    ts_job job = {.run = op_run, .done = op_done, .release = op_release, .ctx = op};
    if (!ts_jobs_submit(&st->jobs, job)) {
        op_release(op); /* not accepted: we still own it */
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
    st->api.base = st->cfg.api_base;
    if (!ts_jobs_start(&st->jobs, st)) {
        ts_http_global_cleanup();
        return false;
    }
    return true;
}

void ts_store_pump(ts_store *st) {
    st->frames++;
    ts_jobs_pump(&st->jobs);
}

void ts_store_shutdown(ts_store *st) {
    ts_http_cancel_all(); /* a running transfer stops at once */
    ts_jobs_stop(&st->jobs);
    ts_http_global_cleanup();
}

bool ts_store_busy(ts_store *st) {
    return ts_jobs_in_flight(&st->jobs) > 0;
}

bool ts_store_check_health(ts_store *st) {
    return submit(st, OP_HEALTH);
}

bool ts_store_call_me(ts_store *st) {
    return submit(st, OP_ME);
}

void ts_store_dismiss_problem(ts_store *st) {
    st->has_problem = false;
}
