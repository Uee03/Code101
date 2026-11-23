#ifndef TS_MODEL_H
#define TS_MODEL_H

#include <stdbool.h>
#include <stddef.h>

#include "util.h"

#define TS_ID_LEN 40
#define TS_TITLE_LEN 808     /* 200 characters at up to 4 bytes each, plus the terminator */
#define TS_DESC_FORM_LEN 4096
#define TS_CURSOR_LEN 256

/* ---- A small generic vector. It owns its items and the destructor says how to free one. ---- */
typedef void (*ts_free_item_fn)(void *item);

typedef struct {
    void *items;
    size_t len;
    size_t cap;
    size_t elem_size;
    ts_free_item_fn free_item; /* may be NULL for plain structs */
} ts_vec;

void ts_vec_init(ts_vec *v, size_t elem_size, ts_free_item_fn free_item);
bool ts_vec_push(ts_vec *v, const void *elem); /* copies the bytes: the caller must not free elem again */
void *ts_vec_at(const ts_vec *v, size_t i);
void ts_vec_remove(ts_vec *v, size_t i);       /* frees item i and closes the gap */
void ts_vec_free(ts_vec *v);

/* ---- Problem details (RFC 9457) ---- */
#define TS_PROBLEM_FIELDS 6

typedef struct {
    char pointer[64];
    char detail[128];
} ts_field_error;

typedef struct {
    long status; /* HTTP status; 0 = no answer arrived (transport failure) */
    char type[128];
    char title[128];
    char detail[256];
    char trace_id[64];
    long retry_after_s; /* -1 = none */
    ts_field_error fields[TS_PROBLEM_FIELDS];
    int field_count;
} ts_problem;

void ts_problem_clear(ts_problem *p);
void ts_problem_transport(ts_problem *p, const char *text);
void ts_problem_add_field(ts_problem *p, const char *pointer, const char *detail);
void ts_problem_parse(const char *body, size_t len, long status, const char *content_type, long retry_after_s,
                      ts_problem *p);
void ts_problem_message(const ts_problem *p, char *out, size_t cap); /* one user-facing sentence */

/* ---- Domain records. Display-only text is bounded and may be cut; edited text never is. ---- */
typedef struct {
    char status[16];
    char database[16];
    char version[32];
} ts_health;

typedef struct {
    char id[TS_ID_LEN];
    char username[64];
    char display_name[128];
    char email[128];
    char roles[96];
} ts_me;

typedef struct {
    char id[TS_ID_LEN];
    char name[96];
    char description[512];
    int member_count;
    long version;
} ts_team;

typedef struct {
    char id[TS_ID_LEN];
    char key[16];
    char name[128];
    bool archived;
    long version;
} ts_project;

typedef struct {
    char id[TS_ID_LEN];
    char project_id[TS_ID_LEN];
    char title[TS_TITLE_LEN];
    char *description; /* owned: freed by ts_task_free */
    char status[16];
    char priority[16];
    char assignee_id[TS_ID_LEN];
    char due_date[16];
    char completed_at[40];
    long version;
} ts_task;

void ts_task_free(ts_task *t); /* frees description and resets t to zero */
bool ts_task_clone(ts_task *dst, const ts_task *src);

typedef struct {
    ts_vec items;
    char next_cursor[TS_CURSOR_LEN]; /* opaque; empty = last page */
} ts_page;

void ts_page_init_teams(ts_page *p);
void ts_page_init_projects(ts_page *p);
void ts_page_init_tasks(ts_page *p);
void ts_page_free(ts_page *p);

/* Parsers: json is not NUL-terminated (len bytes). true = parsed; the out value then owns its memory.
   On false nothing is owned by out. */
bool ts_parse_health(const char *json, size_t len, ts_health *out);
bool ts_parse_me(const char *json, size_t len, ts_me *out);
bool ts_parse_team_page(const char *json, size_t len, ts_page *out);
bool ts_parse_project_page(const char *json, size_t len, ts_page *out);
bool ts_parse_task_page(const char *json, size_t len, ts_page *out);
bool ts_parse_task(const char *json, size_t len, ts_task *out);

/* ---- The task form's data and its checks ---- */
typedef struct {
    char title[TS_TITLE_LEN];
    char description[TS_DESC_FORM_LEN];
    char status[16];
    char priority[16];
    char due_date[16]; /* "" = none */
} ts_task_draft;

#define TS_F_TITLE 1u
#define TS_F_DESCRIPTION 2u
#define TS_F_STATUS 4u
#define TS_F_PRIORITY 8u
#define TS_F_DUE 16u

extern const char *const TS_STATUSES[5];
extern const char *const TS_PRIORITIES[4];

/* Copies a task into a draft. false = the description did not fit the form buffer. */
bool ts_draft_from_task(ts_task_draft *d, const ts_task *t);
/* Checks only the fields in mask against the OpenAPI limits. false fills err like a 422. */
bool ts_draft_validate(const ts_task_draft *d, unsigned mask, ts_problem *err);

#endif
