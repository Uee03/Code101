#include "log.h"

#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"

static bool g_enabled;

void ts_log_init(void) {
    const char *value = getenv("TASKS_LOG");
    g_enabled = value != NULL && strcmp(value, "1") == 0;
}

bool ts_log_enabled(void) {
    return g_enabled;
}

static const char *const MARKERS[] = {
    "Bearer ",        "access_token=",    "refresh_token=",    "id_token=",
    "code_verifier=", "code=",            "access_token\":\"", "refresh_token\":\"",
    "id_token\":\"",
};

static bool starts_with_nocase(const char *s, const char *prefix) {
    for (; *prefix != '\0'; s++, prefix++) {
        if (*s == '\0' || tolower((unsigned char)*s) != tolower((unsigned char)*prefix)) return false;
    }
    return true;
}

static bool is_value_end(char c) {
    return c == '\0' || c == '&' || c == '"' || c == ' ' || c == '\r' || c == '\n' || c == ',' || c == ';';
}

static bool is_token_char(char c) {
    return isalnum((unsigned char)c) || c == '_' || c == '-' || c == '.';
}

/* Appends n bytes, never writing past out[cap - 1]: the last byte is kept for the terminator. */
static void emit(char *out, size_t cap, size_t *o, const char *s, size_t n) {
    size_t room = cap - 1 - *o;
    if (n > room) n = room;
    memcpy(out + *o, s, n);
    *o += n;
}

size_t ts_log_redact(const char *in, char *out, size_t cap) {
    if (out == NULL || cap == 0) return 0;
    size_t o = 0;
    size_t i = 0;
    while (in[i] != '\0') {
        size_t marker_len = 0;
        for (size_t m = 0; m < sizeof MARKERS / sizeof MARKERS[0]; m++) {
            if (starts_with_nocase(in + i, MARKERS[m])) {
                marker_len = strlen(MARKERS[m]);
                break;
            }
        }
        if (marker_len != 0) {
            emit(out, cap, &o, in + i, marker_len);
            i += marker_len;
            while (!is_value_end(in[i])) i++;
            emit(out, cap, &o, "[redacted]", 10);
        } else if (strncmp(in + i, "eyJ", 3) == 0) {
            while (is_token_char(in[i])) i++;
            emit(out, cap, &o, "[jwt]", 5);
        } else {
            emit(out, cap, &o, in + i, 1);
            i++;
        }
    }
    out[o] = '\0';
    return o;
}

void ts_logf(const char *fmt, ...) {
    if (!g_enabled) return;
    char raw[512];
    char safe[640];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(raw, sizeof raw, fmt, ap); /* a long line is cut, never overflowed */
    va_end(ap);
    ts_log_redact(raw, safe, sizeof safe);
    fprintf(stderr, "[%llu ms] %s\n", (unsigned long long)ts_now_ms(), safe);
}
