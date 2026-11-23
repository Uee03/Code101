#include "model.h"

#include <cjson/cJSON.h>
#include <stdint.h>
#include <string.h>

const char *const TS_STATUSES[5] = {"todo", "in_progress", "blocked", "done", "cancelled"};
const char *const TS_PRIORITIES[4] = {"low", "medium", "high", "urgent"};

/* ---------------------------------------------------------------- vector */

void ts_vec_init(ts_vec *v, size_t elem_size, ts_free_item_fn free_item) {
    v->items = NULL;
    v->len = 0;
    v->cap = 0;
    v->elem_size = elem_size;
    v->free_item = free_item;
}

bool ts_vec_push(ts_vec *v, const void *elem) {
    if (v->len == v->cap) {
        if (v->cap > SIZE_MAX / 2) return false;
        size_t cap = v->cap != 0 ? v->cap * 2 : 8;
        if (cap > SIZE_MAX / v->elem_size) return false;
        void *grown = ts_realloc(v->items, cap * v->elem_size);
        if (grown == NULL) return false; /* v->items is untouched and still owned by v */
        v->items = grown;
        v->cap = cap;
    }
    memcpy((char *)v->items + v->len * v->elem_size, elem, v->elem_size);
    v->len++;
    return true;
}

void *ts_vec_at(const ts_vec *v, size_t i) {
    return i < v->len ? (char *)v->items + i * v->elem_size : NULL;
}

void ts_vec_remove(ts_vec *v, size_t i) {
    if (i >= v->len) return;
    char *base = v->items;
    if (v->free_item != NULL) v->free_item(base + i * v->elem_size);
    memmove(base + i * v->elem_size, base + (i + 1) * v->elem_size, (v->len - i - 1) * v->elem_size);
    v->len--;
}

void ts_vec_free(ts_vec *v) {
    if (v->free_item != NULL) {
        for (size_t i = 0; i < v->len; i++) v->free_item((char *)v->items + i * v->elem_size);
    }
    ts_free(v->items);
    v->items = NULL;
    v->len = 0;
    v->cap = 0;
}

/* ---------------------------------------------------------------- JSON helpers */

static void get_str(const cJSON *obj, const char *key, char *dst, size_t cap) {
    const cJSON *item = cJSON_GetObjectItemCaseSensitive(obj, key);
    if (cJSON_IsString(item) && item->valuestring != NULL) {
        ts_copy(dst, cap, item->valuestring); /* display text: a cut is acceptable here */
    } else {
        dst[0] = '\0';
    }
}

static long get_long(const cJSON *obj, const char *key) {
    const cJSON *item = cJSON_GetObjectItemCaseSensitive(obj, key);
    if (!cJSON_IsNumber(item)) return 0;
    double d = item->valuedouble;
    return (d >= 0.0 && d <= 2147483647.0) ? (long)d : 0;
}

static bool get_bool(const cJSON *obj, const char *key) {
    return cJSON_IsTrue(cJSON_GetObjectItemCaseSensitive(obj, key));
}

/* ---------------------------------------------------------------- problem details */

static const struct {
    const char *suffix;
    const char *text;
} MESSAGES[] = {
    {"bad-request", "The request was not understood. Reload and try again."},
    {"unauthorized", "Your session has ended. Sign in again."},
    {"forbidden", "You are not allowed to do that."},
    {"not-found", "That item no longer exists, or you cannot see it."},
    {"conflict", "That conflicts with existing data (a duplicate or a broken rule)."},
    {"precondition-failed", "Someone else changed this item. Review their version before saving."},
    {"validation-error", "Some fields are not valid."},
    {"precondition-required", "The app did not send a version (a bug). Reload and try again."},
    {"rate-limited", "Too many requests. Wait a moment."},
    {"payload-too-large", "The request is too large."},
    {"internal-error", "The server failed. Try again later and quote the trace id."},
};

void ts_problem_clear(ts_problem *p) {
    memset(p, 0, sizeof *p);
    p->retry_after_s = -1;
}

void ts_problem_transport(ts_problem *p, const char *text) {
    ts_problem_clear(p);
    ts_copy(p->detail, sizeof p->detail, text);
}

void ts_problem_add_field(ts_problem *p, const char *pointer, const char *detail) {
    if (p->field_count >= TS_PROBLEM_FIELDS) return;
    ts_field_error *f = &p->fields[p->field_count++];
    ts_copy(f->pointer, sizeof f->pointer, pointer);
    ts_copy(f->detail, sizeof f->detail, detail);
}

void ts_problem_parse(const char *body, size_t len, long status, const char *content_type, long retry_after_s,
                      ts_problem *p) {
    ts_problem_clear(p);
    p->status = status;
    p->retry_after_s = retry_after_s;

    cJSON *root = NULL;
    if (content_type != NULL && strstr(content_type, "json") != NULL) root = cJSON_ParseWithLength(body, len);
    if (root != NULL) {
        get_str(root, "type", p->type, sizeof p->type);
        get_str(root, "title", p->title, sizeof p->title);
        get_str(root, "detail", p->detail, sizeof p->detail);
        get_str(root, "traceId", p->trace_id, sizeof p->trace_id);
        const cJSON *errors = cJSON_GetObjectItemCaseSensitive(root, "errors");
        const cJSON *e;
        cJSON_ArrayForEach(e, errors) {
            char pointer[64], detail[128];
            get_str(e, "pointer", pointer, sizeof pointer);
            get_str(e, "detail", detail, sizeof detail);
            ts_problem_add_field(p, pointer, detail);
        }
    }
    cJSON_Delete(root); /* NULL is allowed */
    if (p->title[0] == '\0') ts_setf(p->title, sizeof p->title, "HTTP %ld", status);
}

void ts_problem_message(const ts_problem *p, char *out, size_t cap) {
    if (p->status == 0) {
        ts_setf(out, cap, "Could not complete the request: %s", p->detail);
        return;
    }
    const char *slash = strrchr(p->type, '/');
    const char *suffix = slash != NULL ? slash + 1 : p->type;
    const char *text = NULL;
    for (size_t i = 0; i < sizeof MESSAGES / sizeof MESSAGES[0]; i++) {
        if (strcmp(suffix, MESSAGES[i].suffix) == 0) {
            text = MESSAGES[i].text;
            break;
        }
    }
    ts_setf(out, cap, "%s (HTTP %ld)", text != NULL ? text : p->title, p->status);
    if (p->retry_after_s >= 0) ts_catf(out, cap, " Try again in %ld s.", p->retry_after_s);
}

/* ---------------------------------------------------------------- records */

void ts_task_free(ts_task *t) {
    ts_free(t->description);
    memset(t, 0, sizeof *t);
}

bool ts_task_clone(ts_task *dst, const ts_task *src) {
    *dst = *src; /* copies the pointer too: replace it by a private copy */
    dst->description = ts_strdup(src->description != NULL ? src->description : "");
    if (dst->description == NULL) {
        memset(dst, 0, sizeof *dst);
        return false;
    }
    return true;
}

static void task_free_item(void *item) {
    ts_task_free(item);
}

void ts_page_init_teams(ts_page *p) {
    ts_vec_init(&p->items, sizeof(ts_team), NULL);
    p->next_cursor[0] = '\0';
}

void ts_page_init_projects(ts_page *p) {
    ts_vec_init(&p->items, sizeof(ts_project), NULL);
    p->next_cursor[0] = '\0';
}

void ts_page_init_tasks(ts_page *p) {
    ts_vec_init(&p->items, sizeof(ts_task), task_free_item);
    p->next_cursor[0] = '\0';
}

void ts_page_free(ts_page *p) {
    ts_vec_free(&p->items);
    p->next_cursor[0] = '\0';
}

/* ---------------------------------------------------------------- parsers */

static bool team_from_json(const cJSON *o, void *out) {
    ts_team *t = out;
    memset(t, 0, sizeof *t);
    if (!cJSON_IsObject(o)) return false;
    get_str(o, "id", t->id, sizeof t->id);
    get_str(o, "name", t->name, sizeof t->name);
    get_str(o, "description", t->description, sizeof t->description);
    t->member_count = (int)get_long(o, "memberCount");
    t->version = get_long(o, "version");
    return t->id[0] != '\0';
}

static bool project_from_json(const cJSON *o, void *out) {
    ts_project *p = out;
    memset(p, 0, sizeof *p);
    if (!cJSON_IsObject(o)) return false;
    get_str(o, "id", p->id, sizeof p->id);
    get_str(o, "key", p->key, sizeof p->key);
    get_str(o, "name", p->name, sizeof p->name);
    p->archived = get_bool(o, "archived");
    p->version = get_long(o, "version");
    return p->id[0] != '\0';
}

static bool task_from_json(const cJSON *o, void *out) {
    ts_task *t = out;
    memset(t, 0, sizeof *t);
    if (!cJSON_IsObject(o)) return false;
    get_str(o, "id", t->id, sizeof t->id);
    get_str(o, "projectId", t->project_id, sizeof t->project_id);
    get_str(o, "title", t->title, sizeof t->title);
    get_str(o, "status", t->status, sizeof t->status);
    get_str(o, "priority", t->priority, sizeof t->priority);
    get_str(o, "assigneeId", t->assignee_id, sizeof t->assignee_id);
    get_str(o, "dueDate", t->due_date, sizeof t->due_date);
    get_str(o, "completedAt", t->completed_at, sizeof t->completed_at);
    t->version = get_long(o, "version");
    const cJSON *d = cJSON_GetObjectItemCaseSensitive(o, "description");
    t->description = ts_strdup(cJSON_IsString(d) && d->valuestring != NULL ? d->valuestring : "");
    if (t->description == NULL) return false;
    if (t->id[0] == '\0' || t->version < 1) { /* the app cannot work with a task without id and version */
        ts_task_free(t);
        return false;
    }
    return true;
}

typedef bool (*item_parse_fn)(const cJSON *o, void *out);

static bool parse_page(const char *json, size_t len, ts_page *page, item_parse_fn parse_item) {
    cJSON *root = cJSON_ParseWithLength(json, len);
    if (root == NULL) return false;
    const cJSON *items = cJSON_GetObjectItemCaseSensitive(root, "items");
    bool ok = cJSON_IsArray(items);
    if (ok) {
        const cJSON *it;
        cJSON_ArrayForEach(it, items) {
            union {
                ts_team team;
                ts_project project;
                ts_task task;
            } scratch;
            if (!parse_item(it, &scratch)) {
                ok = false;
                break;
            }
            if (!ts_vec_push(&page->items, &scratch)) {
                if (page->items.free_item != NULL) page->items.free_item(&scratch);
                ok = false;
                break;
            }
            /* scratch was moved into the vector: it must not be freed again */
        }
    }
    if (ok) {
        const cJSON *info = cJSON_GetObjectItemCaseSensitive(root, "page");
        const cJSON *next = cJSON_GetObjectItemCaseSensitive(info, "nextCursor");
        if (cJSON_IsString(next) && next->valuestring != NULL) {
            ok = ts_copy(page->next_cursor, sizeof page->next_cursor, next->valuestring);
        }
    }
    cJSON_Delete(root);
    if (!ok) ts_page_free(page);
    return ok;
}

bool ts_parse_team_page(const char *json, size_t len, ts_page *out) {
    ts_page_init_teams(out);
    return parse_page(json, len, out, team_from_json);
}

bool ts_parse_project_page(const char *json, size_t len, ts_page *out) {
    ts_page_init_projects(out);
    return parse_page(json, len, out, project_from_json);
}

bool ts_parse_task_page(const char *json, size_t len, ts_page *out) {
    ts_page_init_tasks(out);
    return parse_page(json, len, out, task_from_json);
}

bool ts_parse_task(const char *json, size_t len, ts_task *out) {
    cJSON *root = cJSON_ParseWithLength(json, len);
    if (root == NULL) return false;
    bool ok = task_from_json(root, out);
    cJSON_Delete(root);
    return ok;
}

bool ts_parse_health(const char *json, size_t len, ts_health *out) {
    memset(out, 0, sizeof *out);
    cJSON *root = cJSON_ParseWithLength(json, len);
    if (root == NULL) return false;
    get_str(root, "status", out->status, sizeof out->status);
    get_str(root, "database", out->database, sizeof out->database);
    get_str(root, "version", out->version, sizeof out->version);
    bool ok = cJSON_IsObject(root) && out->status[0] != '\0';
    cJSON_Delete(root);
    return ok;
}

bool ts_parse_me(const char *json, size_t len, ts_me *out) {
    memset(out, 0, sizeof *out);
    cJSON *root = cJSON_ParseWithLength(json, len);
    if (root == NULL) return false;
    get_str(root, "id", out->id, sizeof out->id);
    get_str(root, "username", out->username, sizeof out->username);
    get_str(root, "displayName", out->display_name, sizeof out->display_name);
    get_str(root, "email", out->email, sizeof out->email);
    const cJSON *role;
    cJSON_ArrayForEach(role, cJSON_GetObjectItemCaseSensitive(root, "roles")) {
        if (cJSON_IsString(role) && role->valuestring != NULL) {
            ts_catf(out->roles, sizeof out->roles, "%s%s", out->roles[0] != '\0' ? ", " : "", role->valuestring);
        }
    }
    bool ok = cJSON_IsObject(root) && out->id[0] != '\0';
    cJSON_Delete(root);
    return ok;
}

/* ---------------------------------------------------------------- drafts */

bool ts_draft_from_task(ts_task_draft *d, const ts_task *t) {
    memset(d, 0, sizeof *d);
    ts_copy(d->title, sizeof d->title, t->title);
    ts_copy(d->status, sizeof d->status, t->status);
    ts_copy(d->priority, sizeof d->priority, t->priority);
    ts_copy(d->due_date, sizeof d->due_date, t->due_date);
    return ts_copy(d->description, sizeof d->description, t->description != NULL ? t->description : "");
}

static size_t utf8_length(const char *s) {
    size_t n = 0;
    for (; *s != '\0'; s++) {
        if (((unsigned char)*s & 0xC0) != 0x80) n++;
    }
    return n;
}

static bool in_list(const char *value, const char *const *list, size_t count) {
    for (size_t i = 0; i < count; i++) {
        if (strcmp(value, list[i]) == 0) return true;
    }
    return false;
}

static bool is_date(const char *s) {
    if (strlen(s) != 10) return false;
    for (int i = 0; i < 10; i++) {
        if (i == 4 || i == 7) {
            if (s[i] != '-') return false;
        } else if (s[i] < '0' || s[i] > '9') {
            return false;
        }
    }
    int month = (s[5] - '0') * 10 + (s[6] - '0');
    int day = (s[8] - '0') * 10 + (s[9] - '0');
    return month >= 1 && month <= 12 && day >= 1 && day <= 31;
}

bool ts_draft_validate(const ts_task_draft *d, unsigned mask, ts_problem *err) {
    ts_problem_clear(err);
    err->status = 422;
    ts_copy(err->type, sizeof err->type, "https://code101.example/problems/validation-error");
    ts_copy(err->title, sizeof err->title, "Some fields are not valid");

    if ((mask & TS_F_TITLE) != 0) {
        size_t n = utf8_length(d->title);
        if (n < 1 || n > 200) ts_problem_add_field(err, "/title", "Use 1 to 200 characters.");
    }
    if ((mask & TS_F_STATUS) != 0 && !in_list(d->status, TS_STATUSES, 5)) {
        ts_problem_add_field(err, "/status", "Choose one of the listed statuses.");
    }
    if ((mask & TS_F_PRIORITY) != 0 && !in_list(d->priority, TS_PRIORITIES, 4)) {
        ts_problem_add_field(err, "/priority", "Choose one of the listed priorities.");
    }
    if ((mask & TS_F_DUE) != 0 && d->due_date[0] != '\0' && !is_date(d->due_date)) {
        ts_problem_add_field(err, "/dueDate", "Use the form YYYY-MM-DD, or leave it empty.");
    }
    if (err->field_count == 0) {
        ts_problem_clear(err);
        return true;
    }
    return false;
}
