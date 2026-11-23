#ifndef TS_JOBS_H
#define TS_JOBS_H

#include <SDL3/SDL.h>
#include <stdbool.h>
#include <stddef.h>

#define TS_JOBS_MAX 16

/* A job is a heap context plus three functions:
   run     - on the worker thread; may block; touches only ctx (and read-only shared objects)
   done    - on the main thread, from ts_jobs_pump; takes what it needs out of ctx
   release - on the main thread right after done (or at shutdown); frees what is left of ctx
   Ownership of ctx moves to the queue on a successful submit, to the worker while run executes,
   and to the main thread again in done and release. Nobody touches ctx while someone else owns it. */
typedef void (*ts_job_run_fn)(void *ctx);
typedef void (*ts_job_done_fn)(void *ctx, void *user);
typedef void (*ts_job_release_fn)(void *ctx);

typedef struct {
    ts_job_run_fn run;
    ts_job_done_fn done;
    ts_job_release_fn release;
    void *ctx;
} ts_job;

typedef struct {
    SDL_Thread *thread;
    SDL_Mutex *lock;
    SDL_Condition *wake;
    ts_job waiting[TS_JOBS_MAX];
    size_t waiting_head, waiting_len;
    ts_job finished[TS_JOBS_MAX];
    size_t finished_head, finished_len;
    size_t in_flight; /* waiting + running + finished and not yet pumped */
    bool stopping;
    void *user; /* handed to every done function */
} ts_jobs;

bool ts_jobs_start(ts_jobs *j, void *user);
/* true = the queue owns job.ctx now. false = queue full (or stopped): the caller still owns it. */
bool ts_jobs_submit(ts_jobs *j, ts_job job);
/* Main thread: runs done and release for every finished job. Returns how many. */
int ts_jobs_pump(ts_jobs *j);
size_t ts_jobs_in_flight(ts_jobs *j);
/* Stops the worker (call ts_http_cancel_all first), joins it and releases unfinished jobs without done. */
void ts_jobs_stop(ts_jobs *j);

#endif
