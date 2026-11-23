#ifndef TS_STORE_H
#define TS_STORE_H

#include <stdbool.h>

#include "api.h"
#include "config.h"
#include "jobs.h"
#include "model.h"

/* All application state. Only the main thread reads or writes it.
   The worker thread sees only the ts_op it was given and the read-only api member. */
typedef struct {
    ts_config cfg;
    ts_jobs jobs;
    ts_api api;
    unsigned long frames;

    ts_health health;
    bool have_health;

    ts_problem problem;
    bool has_problem;
    char message[256]; /* the sentence shown for the last problem */
} ts_store;

bool ts_store_init(ts_store *st);
void ts_store_pump(ts_store *st); /* once per frame: runs finished jobs' done handlers */
void ts_store_shutdown(ts_store *st);

bool ts_store_busy(ts_store *st);
bool ts_store_check_health(ts_store *st);
bool ts_store_call_me(ts_store *st); /* without a token on purpose: shows the 401 problem */
void ts_store_dismiss_problem(ts_store *st);

#endif
