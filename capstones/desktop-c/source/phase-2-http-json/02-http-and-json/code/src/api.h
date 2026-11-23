#ifndef TS_API_H
#define TS_API_H

#include <stdbool.h>

#include "http.h"
#include "model.h"

/* Returns a bearer token as a new string (free with ts_secure_free), or NULL when there is none.
   force_refresh asks for a fresh token after a 401. May be called from the worker thread. */
typedef char *(*ts_token_fn)(void *ctx, bool force_refresh);

typedef struct {
    const char *base; /* "http://localhost:8000": borrowed, outlives the api */
    ts_token_fn token;
    void *token_ctx;
} ts_api;

/* Ownership for every function below: on true the out value belongs to the caller
   (ts_page_free, ts_task_free); on false nothing is owned and err describes the problem. */
bool ts_api_health(const ts_api *api, ts_health *out, ts_problem *err);
bool ts_api_me(const ts_api *api, ts_me *out, ts_problem *err);
bool ts_api_list_teams(const ts_api *api, ts_page *out, ts_problem *err);
bool ts_api_list_projects(const ts_api *api, const char *team_id, ts_page *out, ts_problem *err);
/* status may be NULL or "" for all; cursor may be NULL or "" for the first page and is passed through untouched. */
bool ts_api_list_tasks(const ts_api *api, const char *project_id, const char *status, const char *cursor,
                       ts_page *out, ts_problem *err);
bool ts_api_get_task(const ts_api *api, const char *task_id, ts_task *out, ts_problem *err);
bool ts_api_create_task(const ts_api *api, const char *project_id, const ts_task_draft *draft,
                        const char *idempotency_key, ts_task *out, ts_problem *err);
/* mask names the changed fields (TS_F_*): only those go into the merge patch. */
bool ts_api_update_task(const ts_api *api, const char *task_id, long version, const ts_task_draft *draft,
                        unsigned mask, ts_task *out, ts_problem *err);
bool ts_api_complete_task(const ts_api *api, const char *task_id, long version, ts_task *out, ts_problem *err);
bool ts_api_delete_task(const ts_api *api, const char *task_id, long version, ts_problem *err);

/* An id from the server is only put into a URL after this check: 1 to 36 of [A-Za-z0-9-]. */
bool ts_valid_id(const char *s);

#endif
