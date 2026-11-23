#ifndef TS_STORE_H
#define TS_STORE_H

#include <stdbool.h>
#include <stdint.h>

#include "api.h"
#include "auth.h"
#include "config.h"
#include "jobs.h"
#include "model.h"

typedef enum {
    TS_AUTH_SIGNED_OUT,
    TS_AUTH_STARTING,   /* worker: discovery, PKCE, listener */
    TS_AUTH_WAITING,    /* the browser is open, the listener is polled every frame */
    TS_AUTH_EXCHANGING, /* worker: code for tokens, then /v1/me */
    TS_AUTH_SIGNED_IN
} ts_auth_state;

/* The create/edit form. Everything the person typed lives here until it is saved or closed. */
typedef struct {
    bool open;
    bool editing;                  /* false = a new task */
    char task_id[TS_ID_LEN];
    char project_id[TS_ID_LEN];
    long base_version;             /* the version the person saw: it becomes If-Match */
    ts_task_draft draft;           /* what is in the fields now */
    ts_task_draft original;        /* what the server showed when the form opened (or after "keep mine") */
    bool description_locked;       /* the stored description did not fit the form: do not edit or send it */
    int status_index;              /* index into TS_STATUSES */
    int priority_index;            /* index into TS_PRIORITIES */
    char idem_key[40];             /* Idempotency-Key of this create; changes only when the body changes */
    bool sent;
    uint64_t sent_hash;
    bool delete_armed;             /* the first click on Delete only arms it */
    bool conflict;                 /* a 412 happened: theirs holds the current server task */
    ts_task theirs;                /* owned while conflict is true */
} ts_form;

/* All application state. Only the main thread reads or writes it.
   The worker thread sees only the ts_op it was given, the read-only api member and the
   mutex-protected tokens inside auth. */
typedef struct {
    ts_config cfg;
    ts_jobs jobs;
    ts_auth auth;
    ts_api api;
    unsigned long frames;

    ts_auth_state auth_state;
    char sign_in_url[1024];
    char login_message[256];
    ts_me me;
    bool have_me;

    ts_health health;
    bool have_health;

    ts_page teams;
    ts_page projects;
    char team_id[TS_ID_LEN];    /* selected team, "" = none */
    ts_page tasks;
    char project_id[TS_ID_LEN]; /* selected project, "" = none */
    int status_filter;          /* 0 = all, 1..5 = TS_STATUSES[filter - 1] */
    bool loading_more;          /* a "Load more" request is in flight: a second click must not repeat it */
    ts_form form;

    ts_problem problem;
    bool has_problem;
    char message[256]; /* the sentence shown for the last problem */
    char info[256];    /* the line shown for the last success */
} ts_store;

bool ts_store_init(ts_store *st);
void ts_store_pump(ts_store *st); /* once per frame: finished jobs, the sign-in listener, session expiry */
void ts_store_shutdown(ts_store *st);

bool ts_store_busy(ts_store *st);
bool ts_store_check_health(ts_store *st);
void ts_store_dismiss_problem(ts_store *st);

bool ts_store_sign_in(ts_store *st);
void ts_store_cancel_sign_in(ts_store *st);
void ts_store_sign_out(ts_store *st);

/* Teams, projects, tasks */
void ts_store_load_teams(ts_store *st);
void ts_store_select_team(ts_store *st, const char *team_id);
void ts_store_select_project(ts_store *st, const char *project_id);
void ts_store_set_filter(ts_store *st, int filter);
void ts_store_load_more(ts_store *st);

/* The form */
void ts_store_form_new(ts_store *st);
void ts_store_form_edit(ts_store *st, size_t index);
void ts_store_form_close(ts_store *st);
void ts_store_form_save(ts_store *st);
void ts_store_form_complete(ts_store *st);
void ts_store_form_delete(ts_store *st);
void ts_store_form_keep_mine(ts_store *st);
void ts_store_form_take_theirs(ts_store *st);

#endif
