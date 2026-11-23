#include "util.h"

#include <SDL3/SDL.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static SDL_AtomicInt g_live_blocks;

void *ts_malloc(size_t n) {
    void *p = malloc(n == 0 ? 1 : n);
    if (p != NULL) SDL_AddAtomicInt(&g_live_blocks, 1);
    return p;
}

void *ts_calloc(size_t count, size_t size) {
    void *p = (count == 0 || size == 0) ? calloc(1, 1) : calloc(count, size);
    if (p != NULL) SDL_AddAtomicInt(&g_live_blocks, 1);
    return p;
}

void *ts_realloc(void *p, size_t n) {
    void *q = realloc(p, n == 0 ? 1 : n);
    if (q != NULL && p == NULL) SDL_AddAtomicInt(&g_live_blocks, 1);
    return q;
}

void ts_free(void *p) {
    if (p == NULL) return;
    SDL_AddAtomicInt(&g_live_blocks, -1);
    free(p);
}

long ts_alloc_outstanding(void) {
    return (long)SDL_GetAtomicInt(&g_live_blocks);
}

char *ts_strdup(const char *s) {
    if (s == NULL) return NULL;
    size_t n = strlen(s) + 1;
    char *p = ts_malloc(n);
    if (p != NULL) memcpy(p, s, n);
    return p;
}

bool ts_copy(char *dst, size_t cap, const char *src) {
    if (dst == NULL || cap == 0) return false;
    if (src == NULL) {
        dst[0] = '\0';
        return false;
    }
    size_t n = strlen(src);
    if (n < cap) {
        memcpy(dst, src, n + 1);
        return true;
    }
    /* Too long: keep cap - 1 bytes, then step back so no UTF-8 character is cut in half. */
    size_t keep = cap - 1;
    while (keep > 0 && ((unsigned char)src[keep] & 0xC0) == 0x80) keep--;
    memcpy(dst, src, keep);
    dst[keep] = '\0';
    return false;
}

static size_t text_length(const char *s, size_t cap) {
    const char *end = memchr(s, '\0', cap);
    return end != NULL ? (size_t)(end - s) : cap;
}

static bool format_at(char *dst, size_t cap, size_t at, const char *fmt, va_list ap) {
    if (dst == NULL || cap == 0 || at >= cap) return false;
    int n = vsnprintf(dst + at, cap - at, fmt, ap);
    if (n < 0) {
        dst[at] = '\0';
        return false;
    }
    return (size_t)n < cap - at;
}

bool ts_setf(char *dst, size_t cap, const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    bool ok = format_at(dst, cap, 0, fmt, ap);
    va_end(ap);
    return ok;
}

bool ts_catf(char *dst, size_t cap, const char *fmt, ...) {
    if (dst == NULL || cap == 0) return false;
    size_t at = text_length(dst, cap);
    if (at >= cap) return false; /* dst was not terminated: refuse to guess */
    va_list ap;
    va_start(ap, fmt);
    bool ok = format_at(dst, cap, at, fmt, ap);
    va_end(ap);
    return ok;
}

void ts_secure_zero(void *p, size_t n) {
    volatile unsigned char *v = p;
    while (n-- > 0) *v++ = 0;
}

void ts_secure_free(char *s) {
    if (s == NULL) return;
    ts_secure_zero(s, strlen(s));
    ts_free(s);
}

bool ts_secure_equal(const char *a, const char *b) {
    if (a == NULL || b == NULL) return false;
    size_t la = strlen(a), lb = strlen(b);
    size_t n = la < lb ? la : lb;
    unsigned char diff = (unsigned char)(la != lb);
    for (size_t i = 0; i < n; i++) diff |= (unsigned char)(a[i] ^ b[i]);
    return diff == 0;
}

uint64_t ts_now_ms(void) {
    return (uint64_t)SDL_GetTicks();
}

void ts_buf_init(ts_buf *b) {
    b->data = NULL;
    b->len = 0;
    b->cap = 0;
}

bool ts_buf_append(ts_buf *b, const void *p, size_t n, size_t max_total) {
    if (n == 0) return true;
    if (n > SIZE_MAX - b->len - 1) return false;
    if (max_total != 0 && b->len + n > max_total) return false;
    size_t need = b->len + n + 1;
    if (need > b->cap) {
        size_t cap = b->cap != 0 ? b->cap : 256;
        while (cap < need) {
            if (cap > SIZE_MAX / 2) return false;
            cap *= 2;
        }
        char *grown = ts_realloc(b->data, cap);
        if (grown == NULL) return false; /* b->data is still valid and still owned by b */
        b->data = grown;
        b->cap = cap;
    }
    memcpy(b->data + b->len, p, n);
    b->len += n;
    b->data[b->len] = '\0';
    return true;
}

bool ts_buf_appends(ts_buf *b, const char *s) {
    return ts_buf_append(b, s, strlen(s), 0);
}

const char *ts_buf_cstr(const ts_buf *b) {
    return b->data != NULL ? b->data : "";
}

char *ts_buf_take(ts_buf *b) {
    char *d = b->data;
    b->data = NULL;
    b->len = 0;
    b->cap = 0;
    return d;
}

void ts_buf_free(ts_buf *b) {
    ts_free(b->data);
    ts_buf_init(b);
}

void ts_buf_wipe(ts_buf *b) {
    if (b->data != NULL) ts_secure_zero(b->data, b->cap);
    ts_buf_free(b);
}
