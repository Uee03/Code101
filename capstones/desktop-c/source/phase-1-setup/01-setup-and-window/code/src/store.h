#ifndef TS_STORE_H
#define TS_STORE_H

#include <stdbool.h>

#include "config.h"

/* All application state. Only the main thread reads or writes it. */
typedef struct {
    ts_config cfg;
    unsigned long frames;
    char echo[64];
} ts_store;

bool ts_store_init(ts_store *st);
void ts_store_pump(ts_store *st); /* once per frame, before drawing */
void ts_store_shutdown(ts_store *st);

#endif
