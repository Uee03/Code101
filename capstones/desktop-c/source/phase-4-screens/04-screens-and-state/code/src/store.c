#include "store.h"

#include <string.h>

#include "http.h"
#include "pkce.h"

typedef enum {
    OP_HEALTH,
    OP_SIGN_BEGIN,
    OP_SIGN_FINISH,
    OP_SIGN_OUT,
    OP_TEAMS,
    OP_PROJECTS,
    OP_TASKS,
    OP_TASK_CREATE,
    OP_TASK_UPDATE,
    OP_TASK_COMPLETE,
    OP_TASK_DELETE
} ts_op_kind;

/* One job's inputs and outputs. Allocated on the main thread, filled by the worker,
   read by done on the main thread, freed by release. Whatever done moves out must be zeroed
   in the op, so that release never frees it twice. */
typedef struct {
    ts_store *st;
    ts_op_kind kind;
    bool ok;
    ts_problem problem;

    /* inputs */
    char id[TS_ID_LEN];        /* team, project or task id */
    char status[16];           /* OP_TASKS: status filter text, "" = all */
    char cursor[TS_CURSOR_LEN];
    int filter;                /* OP_TASKS: the filter index the answer belongs to */
    bool append;               /* OP_TASKS: "Load more" */
    long version;              /* If-Match */
    unsigned mask;             /* OP_TASK_UPDATE: changed fields */
    char idem[40];             /* OP_TASK_CREATE: Idempotency-Key */
    char code[512];            /* OP_SIGN_FINISH: authorization code */
    char *secret;              /* OP_SIGN_OUT: owns the old refresh token */
    ts_task_draft draft;

    /* outputs */
    ts_health health;
    ts_me me;
    ts_page page;
    ts_task task;
    bool conflict_loaded;      /* OP_TASK_UPDATE: task holds the current server version after a 412 */
    char url[1024];            /* OP_SIGN_BEGIN */
} ts_op;

/* ---------------------------------------------------------------- small helpers */

static void show_problem(ts_store *st, const ts_problem *p) {
    st->problem = *p;
    st->has_problem = true;
    ts_problem_message(p, st->message, sizeof st->message);
}

static void show_text(ts_store *st, const char *text) {
    ts_problem p;
    ts_problem_transport(&p, text);
    show_problem(st, &p);
}

static void move_page(ts_page *dst, ts_page *src) {
    ts_page_free(dst);
    *dst = *src;
    memset(src, 0, sizeof *src); /* moved: the op must not free it again */
}

static int index_of(const char *const *list, int count, const char *value) {
    for (int i = 0; i < count; i++) {
        if (strcmp(list[i], value) == 0) return i;
    }
    return 0;
}

static uint64_t hash_text(uint64_t h, const char *s) {
    for (; *s != '\0'; s++) {
        h ^= (unsigned char)*s;
        h *= 1099511628211ULL;
    }
    h ^= 0xFF; /* separates fields: "ab" + "c" differs from "a" + "bc" */
    h *= 1099511628211ULL;
    return h;
}

static uint64_t hash_draft(const ts_task_draft *d) {
    uint64_t h = 1469598103934665603ULL;
    h = hash_text(h, d->title);
    h = hash_text(h, d->description);
    h = hash_text(h, d->priority);
    return hash_text(h, d->due_date);
}

static void form_clear(ts_form *f) {
    ts_task_free(&f->theirs);
    memset(f, 0, sizeof *f);
}

static void form_load(ts_form *f, const ts_task *t) {
    f->description_locked = !ts_draft_from_task(&f->draft, t);
    f->original = f->draft;
    f->status_index = index_of(TS_STATUSES, 5, t->status);
    f->priority_index = index_of(TS_PRIORITIES, 4, t->priority);
    f->base_version = t->version;
    ts_copy(f->task_id, sizeof f->task_id, t->id);
    ts_copy(f->project_id, sizeof f->project_id, t->project_id);
}

static void reset_workspace(ts_store *st) {
    ts_page_free(&st->teams);
    ts_page_free(&st->projects);
    ts_page_free(&st->tasks);
    st->team_id[0] = '\0';
    st->project_id[0] = '\0';
    st->status_filter = 0;
    st->loading_more = false;
    form_clear(&st->form);
    st->info[0] = '\0';
}

/* Puts *t into the task list, moving it: replaces the task with the same id, or puts a new
   task of the selected project at the front. If t is not moved, the op's release frees it. */
static void put_task(ts_store *st, ts_task *t) {
    ts_vec *v = &st->tasks.items;
    for (size_t i = 0; i < v->len; i++) {
        ts_task *slot = ts_vec_at(v, i);
        if (strcmp(slot->id, t->id) == 0) {
            ts_task_free(slot);
            *slot = *t;
            memset(t, 0, sizeof *t);
            return;
        }
    }
    if (strcmp(t->project_id, st->project_id) != 0) return; /* not on screen */
    if (!ts_vec_push(v, t)) return;
    char *base = v->items;
    size_t size = v->elem_size;
    ts_task last;
    memcpy(&last, base + (v->len - 1) * size, size);
    memmove(base + size, base, (v->len - 1) * size);
    memcpy(base, &last, size);
    memset(t, 0, sizeof *t);
}

static void remove_task(ts_store *st, const char *id) {
    ts_vec *v = &st->tasks.items;
    for (size_t i = 0; i < v->len; i++) {
        ts_task *slot = ts_vec_at(v, i);
        if (strcmp(slot->id, id) == 0) {
            ts_vec_remove(v, i);
            return;
        }
    }
}

/* ---------------------------------------------------------------- jobs */

static void op_run(void *ctx) {
    ts_op *op = ctx; /* worker thread: touches only op, the read-only api and the locked tokens */
    ts_store *st = op->st;
    const ts_api *api = &st->api;
    switch (op->kind) {
    case OP_HEALTH:
        op->ok = ts_api_health(api, &op->health, &op->problem);
        break;
    case OP_SIGN_BEGIN:
        op->ok = ts_auth_begin(&st->auth, op->url, sizeof op->url, &op->problem);
        break;
    case OP_SIGN_FINISH:
        op->ok = ts_auth_finish(&st->auth, op->code, &op->problem) && ts_api_me(api, &op->me, &op->problem);
        break;
    case OP_SIGN_OUT:
        ts_auth_revoke(&st->auth, op->secret);
        op->ok = true;
        break;
    case OP_TEAMS:
        op->ok = ts_api_list_teams(api, &op->page, &op->problem);
        break;
    case OP_PROJECTS:
        op->ok = ts_api_list_projects(api, op->id, &op->page, &op->problem);
        break;
    case OP_TASKS:
        op->ok = ts_api_list_tasks(api, op->id, op->status, op->cursor, &op->page, &op->problem);
        break;
    case OP_TASK_CREATE:
        op->ok = ts_api_create_task(api, op->id, &op->draft, op->idem, &op->task, &op->problem);
        break;
    case OP_TASK_UPDATE:
        op->ok = ts_api_update_task(api, op->id, op->version, &op->draft, op->mask, &op->task, &op->problem);
        if (!op->ok && op->problem.status == 412) {
            ts_problem ignored; /* the 412 problem stays in op->problem for the message */
            op->conflict_loaded = ts_api_get_task(api, op->id, &op->task, &ignored);
        }
        break;
    case OP_TASK_COMPLETE:
        op->ok = ts_api_complete_task(api, op->id, op->version, &op->task, &op->problem);
        break;
    case OP_TASK_DELETE:
        op->ok = ts_api_delete_task(api, op->id, op->version, &op->problem);
        break;
    }
}

static void op_release(void *ctx) {
    ts_op *op = ctx;
    ts_secure_free(op->secret);
    ts_page_free(&op->page);
    ts_task_free(&op->task);
    ts_secure_zero(op, sizeof *op); /* an op may carry a code or a token: wipe before freeing */
    ts_free(op);
}

static ts_op *new_op(ts_store *st, ts_op_kind kind) {
    ts_op *op = ts_calloc(1, sizeof *op);
    if (op == NULL) return NULL;
    op->st = st;
    op->kind = kind;
    return op;
}

static void op_done(void *ctx, void *user);

/* Takes ownership of op in every case: on failure it is released here. */
static bool submit_op(ts_store *st, ts_op *op) {
    ts_job job = {.run = op_run, .done = op_done, .release = op_release, .ctx = op};
    if (ts_jobs_submit(&st->jobs, job)) return true;
    op_release(op); /* the queue did not take it: we still own it */
    show_text(st, "Too many requests are waiting. Try again in a moment.");
    return false;
}

static bool submit_simple(ts_store *st, ts_op_kind kind) {
    ts_op *op = new_op(st, kind);
    return op != NULL && submit_op(st, op);
}

static bool start_tasks(ts_store *st, bool append) {
    ts_op *op = new_op(st, OP_TASKS);
    if (op == NULL) return false;
    ts_copy(op->id, sizeof op->id, st->project_id);
    if (st->status_filter > 0) ts_copy(op->status, sizeof op->status, TS_STATUSES[st->status_filter - 1]);
    op->filter = st->status_filter;
    op->append = append;
    if (append) ts_copy(op->cursor, sizeof op->cursor, st->tasks.next_cursor); /* passed through untouched */
    return submit_op(st, op);
}

/* Applies a page of tasks if it still belongs to what is on screen. */
static void apply_tasks(ts_store *st, ts_op *op) {
    if (op->filter != st->status_filter || strcmp(op->id, st->project_id) != 0) return; /* stale answer: dropped */
    if (!op->append) {
        move_page(&st->tasks, &op->page);
        return;
    }
    ts_vec *src = &op->page.items;
    size_t total = src->len;
    size_t moved = 0;
    while (moved < total && ts_vec_push(&st->tasks.items, ts_vec_at(src, moved))) moved++;
    for (size_t i = moved; i < total; i++) ts_task_free(ts_vec_at(src, i)); /* not moved: free them here */
    src->len = 0;                                                            /* moved or freed: release has nothing left */
    if (moved == total) {
        ts_copy(st->tasks.next_cursor, sizeof st->tasks.next_cursor, op->page.next_cursor);
    } else {
        st->tasks.next_cursor[0] = '\0';
        show_text(st, "Out of memory: the list is incomplete.");
    }
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
            ts_store_load_teams(st);
        } else {
            ts_secure_free(ts_auth_clear(&st->auth)); /* tokens without a working /v1/me are useless */
            st->auth_state = TS_AUTH_SIGNED_OUT;
            ts_problem_message(&op->problem, st->login_message, sizeof st->login_message);
        }
        return;
    case OP_SIGN_OUT:
        return;
    default:
        break;
    }

    if (op->kind == OP_TASKS && op->append) st->loading_more = false;
    if (op->kind >= OP_TEAMS && st->auth_state != TS_AUTH_SIGNED_IN) return; /* the person signed out meanwhile */

    if (!op->ok) {
        if (op->kind == OP_TASK_UPDATE && op->problem.status == 412 && op->conflict_loaded && st->form.open &&
            strcmp(st->form.task_id, op->id) == 0) {
            ts_task_free(&st->form.theirs);
            st->form.theirs = op->task; /* moved: the current server version, for the conflict view */
            memset(&op->task, 0, sizeof op->task);
            st->form.conflict = true;
        }
        show_problem(st, &op->problem);
        return;
    }

    st->has_problem = false;
    switch (op->kind) {
    case OP_HEALTH:
        st->health = op->health;
        st->have_health = true;
        break;
    case OP_TEAMS:
        move_page(&st->teams, &op->page);
        break;
    case OP_PROJECTS:
        if (strcmp(op->id, st->team_id) == 0) move_page(&st->projects, &op->page);
        break;
    case OP_TASKS:
        apply_tasks(st, op);
        break;
    case OP_TASK_CREATE:
        put_task(st, &op->task);
        if (st->form.open && !st->form.editing && strcmp(st->form.idem_key, op->idem) == 0) form_clear(&st->form);
        ts_copy(st->info, sizeof st->info, "Task created.");
        break;
    case OP_TASK_UPDATE:
        put_task(st, &op->task);
        if (st->form.open && strcmp(st->form.task_id, op->id) == 0) form_clear(&st->form);
        ts_copy(st->info, sizeof st->info, "Task saved.");
        break;
    case OP_TASK_COMPLETE:
        if (st->form.open && strcmp(st->form.task_id, op->id) == 0) {
            ts_task_free(&st->form.theirs);
            st->form.conflict = false;
            form_load(&st->form, &op->task); /* the form now shows the completed task and its new version */
        }
        put_task(st, &op->task);
        ts_copy(st->info, sizeof st->info, "Task completed.");
        break;
    case OP_TASK_DELETE:
        remove_task(st, op->id);
        if (st->form.open && strcmp(st->form.task_id, op->id) == 0) form_clear(&st->form);
        ts_copy(st->info, sizeof st->info, "Task deleted.");
        break;
    default:
        break;
    }
}

/* ---------------------------------------------------------------- lifecycle */

bool ts_store_init(ts_store *st) {
    memset(st, 0, sizeof *st);
    ts_config_load(&st->cfg);
    ts_page_init_teams(&st->teams);
    ts_page_init_projects(&st->projects);
    ts_page_init_tasks(&st->tasks);
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

static bool start_exchange(ts_store *st, const char *code) {
    ts_op *op = new_op(st, OP_SIGN_FINISH);
    if (op == NULL) return false;
    if (!ts_copy(op->code, sizeof op->code, code)) {
        op_release(op);
        return false;
    }
    return submit_op(st, op);
}

void ts_store_pump(ts_store *st) {
    st->frames++;
    ts_jobs_pump(&st->jobs);

    if (st->auth_state == TS_AUTH_WAITING) {
        char code[512];
        ts_poll_result r = ts_auth_poll(&st->auth, code, sizeof code, st->login_message, sizeof st->login_message);
        if (r == TS_POLL_CODE) {
            st->auth_state = TS_AUTH_EXCHANGING;
            if (!start_exchange(st, code)) {
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
        reset_workspace(st);
        ts_copy(st->login_message, sizeof st->login_message, "Your session expired. Sign in again.");
    }
}

void ts_store_shutdown(ts_store *st) {
    ts_http_cancel_all(); /* a running transfer stops at once */
    ts_jobs_stop(&st->jobs);
    reset_workspace(st);
    ts_auth_free(&st->auth);
    ts_http_global_cleanup();
}

bool ts_store_busy(ts_store *st) {
    return ts_jobs_in_flight(&st->jobs) > 0;
}

bool ts_store_check_health(ts_store *st) {
    return submit_simple(st, OP_HEALTH);
}

void ts_store_dismiss_problem(ts_store *st) {
    st->has_problem = false;
}

/* ---------------------------------------------------------------- sign-in and sign-out */

bool ts_store_sign_in(ts_store *st) {
    if (st->auth_state != TS_AUTH_SIGNED_OUT) return false;
    st->login_message[0] = '\0';
    st->auth_state = TS_AUTH_STARTING;
    if (!submit_simple(st, OP_SIGN_BEGIN)) {
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
    reset_workspace(st);
    st->login_message[0] = '\0';
    if (refresh == NULL) return;
    ts_op *op = new_op(st, OP_SIGN_OUT);
    if (op == NULL) {
        ts_secure_free(refresh);
        return;
    }
    op->secret = refresh; /* the op owns it from here and wipes it in release */
    submit_op(st, op);
}

/* ---------------------------------------------------------------- teams, projects, tasks */

void ts_store_load_teams(ts_store *st) {
    submit_simple(st, OP_TEAMS);
}

void ts_store_select_team(ts_store *st, const char *team_id) {
    if (!ts_valid_id(team_id) || strcmp(st->team_id, team_id) == 0) return;
    ts_page_free(&st->projects);
    ts_page_free(&st->tasks);
    st->project_id[0] = '\0';
    st->loading_more = false;
    form_clear(&st->form);
    ts_copy(st->team_id, sizeof st->team_id, team_id);

    ts_op *op = new_op(st, OP_PROJECTS);
    if (op == NULL) return;
    ts_copy(op->id, sizeof op->id, team_id);
    submit_op(st, op);
}

void ts_store_select_project(ts_store *st, const char *project_id) {
    if (!ts_valid_id(project_id) || strcmp(st->project_id, project_id) == 0) return;
    ts_page_free(&st->tasks);
    st->loading_more = false;
    form_clear(&st->form);
    ts_copy(st->project_id, sizeof st->project_id, project_id);
    start_tasks(st, false);
}

void ts_store_set_filter(ts_store *st, int filter) {
    if (filter < 0 || filter > 5 || filter == st->status_filter) return;
    st->status_filter = filter;
    st->loading_more = false;
    if (st->project_id[0] != '\0') {
        ts_page_free(&st->tasks);
        start_tasks(st, false);
    }
}

void ts_store_load_more(ts_store *st) {
    if (st->project_id[0] == '\0' || st->tasks.next_cursor[0] == '\0' || st->loading_more) return;
    st->loading_more = start_tasks(st, true);
}

/* ---------------------------------------------------------------- the form */

static unsigned changed_fields(const ts_form *f) {
    unsigned mask = 0;
    if (strcmp(f->draft.title, f->original.title) != 0) mask |= TS_F_TITLE;
    if (!f->description_locked && strcmp(f->draft.description, f->original.description) != 0) mask |= TS_F_DESCRIPTION;
    if (strcmp(f->draft.status, f->original.status) != 0) mask |= TS_F_STATUS;
    if (strcmp(f->draft.priority, f->original.priority) != 0) mask |= TS_F_PRIORITY;
    if (strcmp(f->draft.due_date, f->original.due_date) != 0) mask |= TS_F_DUE;
    return mask;
}

void ts_store_form_new(ts_store *st) {
    if (st->project_id[0] == '\0') return;
    form_clear(&st->form);
    ts_form *f = &st->form;
    ts_copy(f->project_id, sizeof f->project_id, st->project_id);
    ts_copy(f->draft.status, sizeof f->draft.status, "todo");
    ts_copy(f->draft.priority, sizeof f->draft.priority, "medium");
    f->original = f->draft;
    f->status_index = 0;
    f->priority_index = 1;
    if (!ts_random_uuid(f->idem_key)) {
        show_text(st, "The system could not provide random numbers.");
        return;
    }
    f->open = true; /* a new task: one Idempotency-Key per form, created now */
}

void ts_store_form_edit(ts_store *st, size_t index) {
    const ts_task *t = ts_vec_at(&st->tasks.items, index);
    if (t == NULL) return;
    form_clear(&st->form);
    st->form.open = true;
    st->form.editing = true;
    form_load(&st->form, t);
}

void ts_store_form_close(ts_store *st) {
    form_clear(&st->form);
}

void ts_store_form_save(ts_store *st) {
    ts_form *f = &st->form;
    if (!f->open) return;
    ts_copy(f->draft.status, sizeof f->draft.status, TS_STATUSES[f->status_index]);
    ts_copy(f->draft.priority, sizeof f->draft.priority, TS_PRIORITIES[f->priority_index]);

    unsigned mask = f->editing ? changed_fields(f) : (TS_F_TITLE | TS_F_PRIORITY | TS_F_DUE);
    ts_problem err;
    if (!ts_draft_validate(&f->draft, mask, &err)) { /* the same field list as a 422, without a request */
        show_problem(st, &err);
        return;
    }
    if (f->editing && mask == 0) {
        ts_copy(st->info, sizeof st->info, "Nothing was changed.");
        return;
    }

    ts_op *op = new_op(st, f->editing ? OP_TASK_UPDATE : OP_TASK_CREATE);
    if (op == NULL) return;
    op->draft = f->draft;
    if (f->editing) {
        ts_copy(op->id, sizeof op->id, f->task_id);
        op->version = f->base_version;
        op->mask = mask;
    } else {
        uint64_t h = hash_draft(&f->draft);
        if (f->sent && h != f->sent_hash && !ts_random_uuid(f->idem_key)) { /* a changed body needs a new key */
            op_release(op);
            return;
        }
        f->sent = true;
        f->sent_hash = h;
        ts_copy(op->id, sizeof op->id, f->project_id);
        ts_copy(op->idem, sizeof op->idem, f->idem_key);
    }
    submit_op(st, op);
}

void ts_store_form_complete(ts_store *st) {
    ts_form *f = &st->form;
    if (!f->open || !f->editing) return;
    ts_op *op = new_op(st, OP_TASK_COMPLETE);
    if (op == NULL) return;
    ts_copy(op->id, sizeof op->id, f->task_id);
    op->version = f->base_version;
    submit_op(st, op);
}

void ts_store_form_delete(ts_store *st) {
    ts_form *f = &st->form;
    if (!f->open || !f->editing) return;
    if (!f->delete_armed) { /* the first click only arms the button */
        f->delete_armed = true;
        return;
    }
    f->delete_armed = false;
    ts_op *op = new_op(st, OP_TASK_DELETE);
    if (op == NULL) return;
    ts_copy(op->id, sizeof op->id, f->task_id);
    op->version = f->base_version;
    submit_op(st, op);
}

void ts_store_form_keep_mine(ts_store *st) {
    ts_form *f = &st->form;
    if (!f->open || !f->conflict) return;
    bool fits = ts_draft_from_task(&f->original, &f->theirs); /* compare against what the server has now */
    if (!fits) f->description_locked = true;
    f->base_version = f->theirs.version;
    ts_task_free(&f->theirs);
    f->conflict = false;
    ts_store_form_save(st);
}

void ts_store_form_take_theirs(ts_store *st) {
    ts_form *f = &st->form;
    if (!f->open || !f->conflict) return;
    ts_task copy;
    if (ts_task_clone(&copy, &f->theirs)) {
        put_task(st, &copy);
        ts_task_free(&copy); /* put_task zeroed it if it moved it; otherwise this frees it */
    }
    form_load(f, &f->theirs);
    ts_task_free(&f->theirs);
    f->conflict = false;
}
