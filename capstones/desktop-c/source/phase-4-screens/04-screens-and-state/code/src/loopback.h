#ifndef TS_LOOPBACK_H
#define TS_LOOPBACK_H

#include <stdbool.h>
#include <stddef.h>

/* A one-shot web server for the OAuth redirect (RFC 8252, section 7.3).
   It listens on 127.0.0.1 only, on a port the operating system picks, and is polled from the UI loop
   (no thread). The object is created by ts_loopback_open and released with ts_loopback_close. */
typedef struct ts_loopback ts_loopback;

typedef enum { TS_LB_PENDING, TS_LB_DONE, TS_LB_FAILED, TS_LB_TIMEOUT } ts_lb_state;

/* path is the only path that is answered, for example "/callback". NULL on failure. */
ts_loopback *ts_loopback_open(const char *path, int *port_out);

/* Never blocks. On TS_LB_DONE, query holds the text after '?' of the request line (still percent-encoded). */
ts_lb_state ts_loopback_poll(ts_loopback *lb, char *query, size_t query_cap);

void ts_loopback_close(ts_loopback *lb); /* NULL is allowed */

#endif
