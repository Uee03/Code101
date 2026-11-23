#ifndef TS_UTIL_H
#define TS_UTIL_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* Counted allocation: every heap block of this program comes from here.
   ts_free(NULL) is allowed. ts_alloc_outstanding() is the number of live blocks. */
void *ts_malloc(size_t n);
void *ts_calloc(size_t count, size_t size);
void *ts_realloc(void *p, size_t n); /* on failure returns NULL and p stays valid */
void ts_free(void *p);
long ts_alloc_outstanding(void);

/* Returns a copy the caller frees with ts_free, or NULL (s is NULL or no memory). */
char *ts_strdup(const char *s);

/* Bounds-checked text. dst is always NUL-terminated when cap > 0.
   Each function returns false when the text did not fit (the result is cut at a
   UTF-8 character boundary) or when an argument is unusable. */
bool ts_copy(char *dst, size_t cap, const char *src);
bool ts_setf(char *dst, size_t cap, const char *fmt, ...);
bool ts_catf(char *dst, size_t cap, const char *fmt, ...);

/* Secrets: zero memory the compiler may not skip, free a secret string, compare in constant time. */
void ts_secure_zero(void *p, size_t n);
void ts_secure_free(char *s);
bool ts_secure_equal(const char *a, const char *b);

/* Milliseconds from a monotonic clock. */
uint64_t ts_now_ms(void);

/* Growable byte buffer, always NUL-terminated once it holds data.
   The buffer owns data; ts_buf_take hands the block to the caller (free with ts_free). */
typedef struct {
    char *data;
    size_t len;
    size_t cap;
} ts_buf;

void ts_buf_init(ts_buf *b);
bool ts_buf_append(ts_buf *b, const void *p, size_t n, size_t max_total); /* max_total 0 = no limit */
bool ts_buf_appends(ts_buf *b, const char *s);
const char *ts_buf_cstr(const ts_buf *b);
char *ts_buf_take(ts_buf *b);
void ts_buf_free(ts_buf *b);
void ts_buf_wipe(ts_buf *b); /* zero the contents, then free */

#endif
