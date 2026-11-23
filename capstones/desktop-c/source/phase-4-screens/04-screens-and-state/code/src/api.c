#include "api.h"

#include <cjson/cJSON.h>
#include <ctype.h>
#include <string.h>

#define TS_URL_MAX 2048

bool ts_valid_id(const char *s) {
    if (s == NULL) return false;
    size_t n = strlen(s);
    if (n == 0 || n > 36) return false;
    for (size_t i = 0; i < n; i++) {
        if (!isalnum((unsigned char)s[i]) && s[i] != '-') return false;
    }
    return true;
}

static bool bad_url(ts_problem *err) {
    ts_problem_transport(err, "The address or an id is not valid.");
    return false;
}

static bool out_of_memory(ts_problem *err) {
    ts_problem_transport(err, "Out of memory.");
    return false;
}

/* One request with the bearer token. After a 401 it asks for a fresh token and tries once more.
   true = a 2xx answer is in res (the caller frees it). false = err is filled and res is already freed. */
static bool call(const ts_api *api, ts_http_request req, ts_http_response *res, ts_problem *err) {
    for (int attempt = 0; attempt < 2; attempt++) {
        char *token = api->token != NULL ? api->token(api->token_ctx, attempt == 1) : NULL;
        req.bearer = token;
        bool answered = ts_http_send(&req, res);
        ts_secure_free(token);
        if (!answered) {
            ts_problem_transport(err, res->error);
            ts_http_response_free(res);
            return false;
        }
        if (res->status == 401 && attempt == 0 && api->token != NULL) {
            ts_http_response_free(res);
            continue;
        }
        break;
    }
    if (res->status >= 200 && res->status < 300) return true;
    ts_problem_parse(ts_buf_cstr(&res->body), res->body.len, res->status, res->content_type, res->retry_after_s, err);
    ts_http_response_free(res);
    return false;
}

static bool finish(bool parsed, ts_http_response *res, ts_problem *err) {
    ts_http_response_free(res);
    if (!parsed) ts_problem_transport(err, "The server sent an answer the app could not read.");
    return parsed;
}

/* Builds the JSON text of a draft for the fields in mask. Free the result with cJSON_free. */
static char *draft_json(const ts_task_draft *d, unsigned mask) {
    cJSON *o = cJSON_CreateObject();
    if (o == NULL) return NULL;
    bool ok = true;
    if (ok && (mask & TS_F_TITLE) != 0) ok = cJSON_AddStringToObject(o, "title", d->title) != NULL;
    if (ok && (mask & TS_F_DESCRIPTION) != 0) ok = cJSON_AddStringToObject(o, "description", d->description) != NULL;
    if (ok && (mask & TS_F_STATUS) != 0) ok = cJSON_AddStringToObject(o, "status", d->status) != NULL;
    if (ok && (mask & TS_F_PRIORITY) != 0) ok = cJSON_AddStringToObject(o, "priority", d->priority) != NULL;
    if (ok && (mask & TS_F_DUE) != 0) {
        /* JSON Merge Patch: null clears the date, a string sets it */
        ok = (d->due_date[0] != '\0' ? cJSON_AddStringToObject(o, "dueDate", d->due_date)
                                     : cJSON_AddNullToObject(o, "dueDate")) != NULL;
    }
    char *text = ok ? cJSON_PrintUnformatted(o) : NULL;
    cJSON_Delete(o);
    return text;
}

bool ts_api_health(const ts_api *api, ts_health *out, ts_problem *err) {
    ts_api open = *api;
    open.token = NULL; /* /health is public: never send the token there */
    char url[TS_URL_MAX];
    if (!ts_setf(url, sizeof url, "%s/health", api->base)) return bad_url(err);
    ts_http_response res;
    ts_http_response_init(&res);
    if (!call(&open, (ts_http_request){.method = TS_HTTP_GET, .url = url}, &res, err)) return false;
    return finish(ts_parse_health(ts_buf_cstr(&res.body), res.body.len, out), &res, err);
}

bool ts_api_me(const ts_api *api, ts_me *out, ts_problem *err) {
    char url[TS_URL_MAX];
    if (!ts_setf(url, sizeof url, "%s/v1/me", api->base)) return bad_url(err);
    ts_http_response res;
    ts_http_response_init(&res);
    if (!call(api, (ts_http_request){.method = TS_HTTP_GET, .url = url}, &res, err)) return false;
    return finish(ts_parse_me(ts_buf_cstr(&res.body), res.body.len, out), &res, err);
}

bool ts_api_list_teams(const ts_api *api, ts_page *out, ts_problem *err) {
    char url[TS_URL_MAX];
    if (!ts_setf(url, sizeof url, "%s/v1/teams?limit=100", api->base)) return bad_url(err);
    ts_http_response res;
    ts_http_response_init(&res);
    if (!call(api, (ts_http_request){.method = TS_HTTP_GET, .url = url}, &res, err)) return false;
    return finish(ts_parse_team_page(ts_buf_cstr(&res.body), res.body.len, out), &res, err);
}

bool ts_api_list_projects(const ts_api *api, const char *team_id, ts_page *out, ts_problem *err) {
    char url[TS_URL_MAX];
    if (!ts_valid_id(team_id) || !ts_setf(url, sizeof url, "%s/v1/teams/%s/projects", api->base, team_id)) {
        return bad_url(err);
    }
    ts_http_response res;
    ts_http_response_init(&res);
    if (!call(api, (ts_http_request){.method = TS_HTTP_GET, .url = url}, &res, err)) return false;
    return finish(ts_parse_project_page(ts_buf_cstr(&res.body), res.body.len, out), &res, err);
}

bool ts_api_list_tasks(const ts_api *api, const char *project_id, const char *status, const char *cursor,
                       ts_page *out, ts_problem *err) {
    char url[TS_URL_MAX];
    if (!ts_valid_id(project_id) ||
        !ts_setf(url, sizeof url, "%s/v1/projects/%s/tasks?limit=25", api->base, project_id)) {
        return bad_url(err);
    }
    if (status != NULL && status[0] != '\0') {
        char *encoded = ts_url_encode(status);
        if (encoded == NULL) return out_of_memory(err);
        bool fits = ts_catf(url, sizeof url, "&status=%s", encoded);
        ts_free(encoded);
        if (!fits) return bad_url(err);
    }
    if (cursor != NULL && cursor[0] != '\0') {
        char *encoded = ts_url_encode(cursor); /* the cursor is opaque: encoded, never parsed */
        if (encoded == NULL) return out_of_memory(err);
        bool fits = ts_catf(url, sizeof url, "&cursor=%s", encoded);
        ts_free(encoded);
        if (!fits) return bad_url(err);
    }
    ts_http_response res;
    ts_http_response_init(&res);
    if (!call(api, (ts_http_request){.method = TS_HTTP_GET, .url = url}, &res, err)) return false;
    return finish(ts_parse_task_page(ts_buf_cstr(&res.body), res.body.len, out), &res, err);
}

bool ts_api_get_task(const ts_api *api, const char *task_id, ts_task *out, ts_problem *err) {
    char url[TS_URL_MAX];
    if (!ts_valid_id(task_id) || !ts_setf(url, sizeof url, "%s/v1/tasks/%s", api->base, task_id)) {
        return bad_url(err);
    }
    ts_http_response res;
    ts_http_response_init(&res);
    if (!call(api, (ts_http_request){.method = TS_HTTP_GET, .url = url}, &res, err)) return false;
    return finish(ts_parse_task(ts_buf_cstr(&res.body), res.body.len, out), &res, err);
}

bool ts_api_create_task(const ts_api *api, const char *project_id, const ts_task_draft *draft,
                        const char *idempotency_key, ts_task *out, ts_problem *err) {
    char url[TS_URL_MAX];
    if (!ts_valid_id(project_id) ||
        !ts_setf(url, sizeof url, "%s/v1/projects/%s/tasks", api->base, project_id)) {
        return bad_url(err);
    }
    unsigned mask = TS_F_TITLE | TS_F_DESCRIPTION | TS_F_PRIORITY;
    if (draft->due_date[0] != '\0') mask |= TS_F_DUE;
    char *body = draft_json(draft, mask);
    if (body == NULL) return out_of_memory(err);

    ts_http_response res;
    ts_http_response_init(&res);
    bool ok = call(api,
                   (ts_http_request){.method = TS_HTTP_POST,
                                     .url = url,
                                     .idempotency_key = idempotency_key,
                                     .body = body,
                                     .body_len = strlen(body)},
                   &res, err);
    cJSON_free(body); /* memory from cJSON is freed by cJSON */
    if (!ok) return false;
    return finish(ts_parse_task(ts_buf_cstr(&res.body), res.body.len, out), &res, err);
}

bool ts_api_update_task(const ts_api *api, const char *task_id, long version, const ts_task_draft *draft,
                        unsigned mask, ts_task *out, ts_problem *err) {
    char url[TS_URL_MAX];
    char etag[32];
    if (!ts_valid_id(task_id) || !ts_setf(url, sizeof url, "%s/v1/tasks/%s", api->base, task_id) ||
        !ts_setf(etag, sizeof etag, "\"%ld\"", version)) {
        return bad_url(err);
    }
    char *body = draft_json(draft, mask);
    if (body == NULL) return out_of_memory(err);

    ts_http_response res;
    ts_http_response_init(&res);
    bool ok = call(api,
                   (ts_http_request){.method = TS_HTTP_PATCH,
                                     .url = url,
                                     .if_match = etag,
                                     .content_type = "application/merge-patch+json",
                                     .body = body,
                                     .body_len = strlen(body)},
                   &res, err);
    cJSON_free(body);
    if (!ok) return false;
    return finish(ts_parse_task(ts_buf_cstr(&res.body), res.body.len, out), &res, err);
}

bool ts_api_complete_task(const ts_api *api, const char *task_id, long version, ts_task *out, ts_problem *err) {
    char url[TS_URL_MAX];
    char etag[32];
    if (!ts_valid_id(task_id) || !ts_setf(url, sizeof url, "%s/v1/tasks/%s/complete", api->base, task_id) ||
        !ts_setf(etag, sizeof etag, "\"%ld\"", version)) {
        return bad_url(err);
    }
    ts_http_response res;
    ts_http_response_init(&res);
    if (!call(api, (ts_http_request){.method = TS_HTTP_POST, .url = url, .if_match = etag}, &res, err)) return false;
    return finish(ts_parse_task(ts_buf_cstr(&res.body), res.body.len, out), &res, err);
}

bool ts_api_delete_task(const ts_api *api, const char *task_id, long version, ts_problem *err) {
    char url[TS_URL_MAX];
    char etag[32];
    if (!ts_valid_id(task_id) || !ts_setf(url, sizeof url, "%s/v1/tasks/%s", api->base, task_id) ||
        !ts_setf(etag, sizeof etag, "\"%ld\"", version)) {
        return bad_url(err);
    }
    ts_http_response res;
    ts_http_response_init(&res);
    if (!call(api, (ts_http_request){.method = TS_HTTP_DELETE, .url = url, .if_match = etag}, &res, err)) return false;
    ts_http_response_free(&res);
    return true;
}
