#ifndef TS_HTTP_H
#define TS_HTTP_H

#include <stdbool.h>
#include <stddef.h>

#include "util.h"

typedef enum { TS_HTTP_GET, TS_HTTP_POST, TS_HTTP_PATCH, TS_HTTP_DELETE } ts_method;

/* Everything the caller wants sent. All pointers are borrowed and only read during ts_http_send. */
typedef struct {
    ts_method method;
    const char *url;
    const char *bearer;          /* access token, or NULL */
    const char *if_match;        /* quoted ETag such as "3", or NULL */
    const char *idempotency_key; /* or NULL */
    const char *content_type;    /* or NULL: application/json */
    const char *body;            /* or NULL */
    size_t body_len;
} ts_http_request;

/* The answer. The response owns body; ts_http_response_free releases it. */
typedef struct {
    long status;           /* 0 when no HTTP answer arrived */
    ts_buf body;
    char etag[64];
    char content_type[96];
    long retry_after_s;    /* -1 when the header is absent */
    char error[160];       /* transport error text when status is 0 */
} ts_http_response;

bool ts_http_global_init(void);
void ts_http_global_cleanup(void);
void ts_http_cancel_all(void); /* running and later transfers fail at once; used at shutdown */

/* https anywhere; http only to localhost, 127.0.0.1 and [::1]; no user@host. */
bool ts_http_url_allowed(const char *url);

void ts_http_response_init(ts_http_response *r);
void ts_http_response_free(ts_http_response *r); /* releases the body and resets r for reuse */

/* Blocking. true = an HTTP answer arrived (any status, see res->status); false = transport
   failure or policy refusal (res->error says why). res must have been initialised. */
bool ts_http_send(const ts_http_request *req, ts_http_response *res);

/* Percent-encoding. ts_url_encode returns a new string the caller frees with ts_free.
   ts_url_decode works in place (and turns '+' into a space, as in form data). */
char *ts_url_encode(const char *s);
void ts_url_decode(char *s);

#endif
