#include "http.h"

#include <SDL3/SDL.h>
#include <ctype.h>
#include <curl/curl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BODY_BYTES (4u * 1024u * 1024u)
#define MAX_REQUEST_BYTES (64u * 1024u)

static SDL_AtomicInt g_cancel;

bool ts_http_global_init(void) {
    return curl_global_init(CURL_GLOBAL_DEFAULT) == CURLE_OK;
}

void ts_http_global_cleanup(void) {
    curl_global_cleanup();
}

void ts_http_cancel_all(void) {
    SDL_SetAtomicInt(&g_cancel, 1);
}

static bool equals_nocase(const char *a, const char *b) {
    while (*a != '\0' && *b != '\0') {
        if (tolower((unsigned char)*a) != tolower((unsigned char)*b)) return false;
        a++;
        b++;
    }
    return *a == *b;
}

bool ts_http_url_allowed(const char *url) {
    if (url == NULL) return false;
    if (strncmp(url, "https://", 8) == 0) return url[8] != '\0';
    if (strncmp(url, "http://", 7) != 0) return false;

    const char *authority = url + 7;
    size_t alen = strcspn(authority, "/?#");
    if (alen == 0 || memchr(authority, '@', alen) != NULL) return false;

    size_t hlen;
    if (authority[0] == '[') {
        const char *close = memchr(authority, ']', alen);
        if (close == NULL) return false;
        hlen = (size_t)(close - authority) + 1;
    } else {
        const char *colon = memchr(authority, ':', alen);
        hlen = colon != NULL ? (size_t)(colon - authority) : alen;
    }
    char host[64];
    if (hlen == 0 || hlen >= sizeof host) return false;
    memcpy(host, authority, hlen);
    host[hlen] = '\0';
    return equals_nocase(host, "localhost") || strcmp(host, "127.0.0.1") == 0 || strcmp(host, "[::1]") == 0;
}

void ts_http_response_init(ts_http_response *r) {
    memset(r, 0, sizeof *r);
    r->retry_after_s = -1;
}

void ts_http_response_free(ts_http_response *r) {
    ts_buf_free(&r->body);
    ts_http_response_init(r);
}

static bool header_value(const char *line, size_t n, const char *name, char *out, size_t cap) {
    size_t name_len = strlen(name);
    if (n <= name_len || line[name_len] != ':') return false;
    for (size_t i = 0; i < name_len; i++) {
        if (tolower((unsigned char)line[i]) != tolower((unsigned char)name[i])) return false;
    }
    const char *v = line + name_len + 1;
    const char *end = line + n;
    while (v < end && (*v == ' ' || *v == '\t')) v++;
    while (end > v && (end[-1] == '\r' || end[-1] == '\n' || end[-1] == ' ')) end--;
    size_t len = (size_t)(end - v);
    if (len >= cap) len = cap - 1;
    memcpy(out, v, len);
    out[len] = '\0';
    return true;
}

static size_t on_header(char *line, size_t size, size_t nitems, void *userdata) {
    ts_http_response *r = userdata;
    size_t n = size * nitems;
    char value[128];
    if (header_value(line, n, "ETag", value, sizeof value)) {
        ts_copy(r->etag, sizeof r->etag, value);
    } else if (header_value(line, n, "Content-Type", value, sizeof value)) {
        ts_copy(r->content_type, sizeof r->content_type, value);
    } else if (header_value(line, n, "Retry-After", value, sizeof value)) {
        char *end = NULL;
        long seconds = strtol(value, &end, 10);
        if (end != value && seconds >= 0 && seconds <= 86400) r->retry_after_s = seconds;
    }
    return n;
}

static size_t on_body(char *data, size_t size, size_t nmemb, void *userdata) {
    ts_buf *body = userdata;
    size_t n = size * nmemb;
    /* Returning less than n makes curl stop with CURLE_WRITE_ERROR: the 4 MiB cap. */
    return ts_buf_append(body, data, n, MAX_BODY_BYTES) ? n : 0;
}

static int on_progress(void *userdata, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow) {
    (void)userdata;
    (void)dltotal;
    (void)dlnow;
    (void)ultotal;
    (void)ulnow;
    return SDL_GetAtomicInt(&g_cancel) != 0 ? 1 : 0; /* non-zero aborts the transfer */
}

/* Adds "name: prefix value". The temporary line may contain a token, so it is wiped. */
static bool add_header(struct curl_slist **list, const char *name, const char *prefix, const char *value) {
    size_t n = strlen(name) + strlen(prefix) + strlen(value) + 3;
    char *line = ts_malloc(n);
    if (line == NULL) return false;
    if (!ts_setf(line, n, "%s: %s%s", name, prefix, value)) {
        ts_secure_free(line);
        return false;
    }
    struct curl_slist *grown = curl_slist_append(*list, line);
    ts_secure_free(line); /* curl copied it; this copy may hold a token */
    if (grown == NULL) return false;
    *list = grown;
    return true;
}

static void fail(ts_http_response *res, const char *text) {
    ts_copy(res->error, sizeof res->error, text);
    res->status = 0;
}

bool ts_http_send(const ts_http_request *req, ts_http_response *res) {
    if (!ts_http_url_allowed(req->url)) {
        fail(res, "Blocked: use https, or http to localhost only.");
        return false;
    }
    if (req->body_len > MAX_REQUEST_BYTES) {
        fail(res, "Request body is too large.");
        return false;
    }
    if (SDL_GetAtomicInt(&g_cancel) != 0) {
        fail(res, "Cancelled.");
        return false;
    }
    CURL *h = curl_easy_init();
    if (h == NULL) {
        fail(res, "Could not start a transfer.");
        return false;
    }

    struct curl_slist *headers = NULL;
    bool ok = add_header(&headers, "Accept", "", "application/json");
    if (ok && req->bearer != NULL) ok = add_header(&headers, "Authorization", "Bearer ", req->bearer);
    if (ok && req->if_match != NULL) ok = add_header(&headers, "If-Match", "", req->if_match);
    if (ok && req->idempotency_key != NULL) ok = add_header(&headers, "Idempotency-Key", "", req->idempotency_key);
    if (ok && (req->method == TS_HTTP_POST || req->method == TS_HTTP_PATCH)) {
        ok = add_header(&headers, "Content-Type", "", req->content_type != NULL ? req->content_type : "application/json");
    }
    if (!ok) {
        curl_slist_free_all(headers);
        curl_easy_cleanup(h);
        fail(res, "Out of memory while building the request.");
        return false;
    }

    curl_easy_setopt(h, CURLOPT_URL, req->url);
    curl_easy_setopt(h, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(h, CURLOPT_USERAGENT, "TasksTeamsDesktop/1.0");
    curl_easy_setopt(h, CURLOPT_NOSIGNAL, 1L);
    curl_easy_setopt(h, CURLOPT_FOLLOWLOCATION, 0L);
    curl_easy_setopt(h, CURLOPT_PROTOCOLS_STR, "http,https");
    curl_easy_setopt(h, CURLOPT_CONNECTTIMEOUT_MS, 5000L);
    curl_easy_setopt(h, CURLOPT_TIMEOUT_MS, 20000L);
    curl_easy_setopt(h, CURLOPT_ACCEPT_ENCODING, ""); /* let curl decode gzip; the 4 MiB cap counts decoded bytes */
    /* TLS: verification is on by default; the next three lines only make that visible. */
    curl_easy_setopt(h, CURLOPT_SSL_VERIFYPEER, 1L);
    curl_easy_setopt(h, CURLOPT_SSL_VERIFYHOST, 2L);
    curl_easy_setopt(h, CURLOPT_SSLVERSION, (long)CURL_SSLVERSION_TLSv1_2);
    curl_easy_setopt(h, CURLOPT_WRITEFUNCTION, on_body);
    curl_easy_setopt(h, CURLOPT_WRITEDATA, &res->body);
    curl_easy_setopt(h, CURLOPT_HEADERFUNCTION, on_header);
    curl_easy_setopt(h, CURLOPT_HEADERDATA, res);
    curl_easy_setopt(h, CURLOPT_NOPROGRESS, 0L);
    curl_easy_setopt(h, CURLOPT_XFERINFOFUNCTION, on_progress);

    switch (req->method) {
    case TS_HTTP_GET:
        break;
    case TS_HTTP_POST:
        curl_easy_setopt(h, CURLOPT_POST, 1L);
        break;
    case TS_HTTP_PATCH:
        curl_easy_setopt(h, CURLOPT_CUSTOMREQUEST, "PATCH");
        break;
    case TS_HTTP_DELETE:
        curl_easy_setopt(h, CURLOPT_CUSTOMREQUEST, "DELETE");
        break;
    }
    if (req->method == TS_HTTP_POST || req->method == TS_HTTP_PATCH) {
        curl_easy_setopt(h, CURLOPT_POSTFIELDS, req->body != NULL ? req->body : "");
        curl_easy_setopt(h, CURLOPT_POSTFIELDSIZE_LARGE, (curl_off_t)req->body_len);
    }

    CURLcode rc = curl_easy_perform(h);
    bool got_answer = false;
    if (rc == CURLE_OK) {
        long status = 0;
        curl_easy_getinfo(h, CURLINFO_RESPONSE_CODE, &status);
        res->status = status;
        got_answer = true;
    } else if (rc == CURLE_ABORTED_BY_CALLBACK) {
        fail(res, "Cancelled.");
    } else if (rc == CURLE_WRITE_ERROR) {
        fail(res, "The response was too large or memory ran out.");
    } else {
        fail(res, curl_easy_strerror(rc));
    }

    curl_slist_free_all(headers);
    curl_easy_cleanup(h);
    return got_answer;
}

static bool is_unreserved(unsigned char c) {
    return isalnum(c) || c == '-' || c == '.' || c == '_' || c == '~';
}

char *ts_url_encode(const char *s) {
    size_t len = strlen(s);
    if (len > (SIZE_MAX - 1) / 3) return NULL; /* 3 * len + 1 would wrap around */
    char *out = ts_malloc(len * 3 + 1);
    if (out == NULL) return NULL;
    static const char hex[] = "0123456789ABCDEF";
    size_t o = 0;
    for (size_t i = 0; i < len; i++) {
        unsigned char c = (unsigned char)s[i];
        if (is_unreserved(c)) {
            out[o++] = (char)c;
        } else {
            out[o++] = '%';
            out[o++] = hex[c >> 4];
            out[o++] = hex[c & 15];
        }
    }
    out[o] = '\0';
    return out;
}

static int hex_value(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

void ts_url_decode(char *s) {
    char *w = s;
    for (const char *r = s; *r != '\0'; r++) {
        if (*r == '%' && hex_value(r[1]) >= 0 && hex_value(r[2]) >= 0) {
            *w++ = (char)(hex_value(r[1]) * 16 + hex_value(r[2]));
            r += 2;
        } else if (*r == '+') {
            *w++ = ' ';
        } else {
            *w++ = *r;
        }
    }
    *w = '\0';
}
