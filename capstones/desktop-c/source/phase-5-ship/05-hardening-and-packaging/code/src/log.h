#ifndef TS_LOG_H
#define TS_LOG_H

#include <stdbool.h>
#include <stddef.h>

/* The compiler checks the arguments against the format string (FIO30-C): the format must be a literal. */
#if defined(__GNUC__) || defined(__clang__)
#define TS_PRINTF_LIKE(format_index, first_arg) __attribute__((format(printf, format_index, first_arg)))
#else
#define TS_PRINTF_LIKE(format_index, first_arg)
#endif

/* Reads TASKS_LOG: the value "1" switches logging on. Off by default. */
void ts_log_init(void);
bool ts_log_enabled(void);

/* One line to stderr with a millisecond stamp. The text is passed through ts_log_redact first. */
void ts_logf(const char *fmt, ...) TS_PRINTF_LIKE(1, 2);

/* Copies in to out (capacity cap) and replaces secrets by a marker: the value after "Bearer ",
   "access_token=", "refresh_token=", "id_token=", "code=", "code_verifier=" (and the JSON forms
   "access_token":"...") and any run that starts with "eyJ" (the start of a JWT). It errs on the
   side of hiding too much. Returns the length written; out is always terminated when cap > 0. */
size_t ts_log_redact(const char *in, char *out, size_t cap);

#endif
