#include "jobs.h"

#include <string.h>

static int worker_main(void *data) {
    ts_jobs *j = data;
    SDL_LockMutex(j->lock);
    for (;;) {
        while (j->waiting_len == 0 && !j->stopping) SDL_WaitCondition(j->wake, j->lock);
        if (j->stopping) break;

        ts_job job = j->waiting[j->waiting_head];
        j->waiting_head = (j->waiting_head + 1) % TS_JOBS_MAX;
        j->waiting_len--;

        SDL_UnlockMutex(j->lock); /* never hold the lock while the job blocks on the network */
        job.run(job.ctx);
        SDL_LockMutex(j->lock);

        j->finished[(j->finished_head + j->finished_len) % TS_JOBS_MAX] = job;
        j->finished_len++;
    }
    SDL_UnlockMutex(j->lock);
    return 0;
}

bool ts_jobs_start(ts_jobs *j, void *user) {
    memset(j, 0, sizeof *j);
    j->user = user;
    j->lock = SDL_CreateMutex();
    j->wake = SDL_CreateCondition();
    if (j->lock != NULL && j->wake != NULL) j->thread = SDL_CreateThread(worker_main, "jobs", j);
    if (j->thread == NULL) {
        if (j->wake != NULL) SDL_DestroyCondition(j->wake);
        if (j->lock != NULL) SDL_DestroyMutex(j->lock);
        memset(j, 0, sizeof *j);
        return false;
    }
    return true;
}

bool ts_jobs_submit(ts_jobs *j, ts_job job) {
    bool accepted = false;
    SDL_LockMutex(j->lock);
    if (!j->stopping && j->in_flight < TS_JOBS_MAX) {
        j->waiting[(j->waiting_head + j->waiting_len) % TS_JOBS_MAX] = job;
        j->waiting_len++;
        j->in_flight++;
        accepted = true;
        SDL_SignalCondition(j->wake);
    }
    SDL_UnlockMutex(j->lock);
    return accepted;
}

int ts_jobs_pump(ts_jobs *j) {
    int count = 0;
    for (;;) {
        SDL_LockMutex(j->lock);
        if (j->finished_len == 0) {
            SDL_UnlockMutex(j->lock);
            return count;
        }
        ts_job job = j->finished[j->finished_head];
        j->finished_head = (j->finished_head + 1) % TS_JOBS_MAX;
        j->finished_len--;
        j->in_flight--;
        SDL_UnlockMutex(j->lock);

        if (job.done != NULL) job.done(job.ctx, j->user);
        if (job.release != NULL) job.release(job.ctx);
        count++;
    }
}

size_t ts_jobs_in_flight(ts_jobs *j) {
    SDL_LockMutex(j->lock);
    size_t n = j->in_flight;
    SDL_UnlockMutex(j->lock);
    return n;
}

void ts_jobs_stop(ts_jobs *j) {
    if (j->thread == NULL) return;
    SDL_LockMutex(j->lock);
    j->stopping = true;
    SDL_BroadcastCondition(j->wake);
    SDL_UnlockMutex(j->lock);
    SDL_WaitThread(j->thread, NULL);
    j->thread = NULL;

    /* The worker is gone: this thread owns every queue again. */
    while (j->waiting_len > 0) {
        ts_job job = j->waiting[j->waiting_head];
        j->waiting_head = (j->waiting_head + 1) % TS_JOBS_MAX;
        j->waiting_len--;
        if (job.release != NULL) job.release(job.ctx);
    }
    while (j->finished_len > 0) {
        ts_job job = j->finished[j->finished_head];
        j->finished_head = (j->finished_head + 1) % TS_JOBS_MAX;
        j->finished_len--;
        if (job.release != NULL) job.release(job.ctx);
    }
    j->in_flight = 0;
    SDL_DestroyCondition(j->wake);
    SDL_DestroyMutex(j->lock);
    j->wake = NULL;
    j->lock = NULL;
}
