#include "ui.h"

static void problem_panel(struct nk_context *nk, ts_store *st) {
    nk_layout_row_dynamic(nk, 52, 1);
    nk_label_wrap(nk, st->message);
    nk_layout_row_dynamic(nk, 26, 1);
    if (st->problem.detail[0] != '\0') nk_labelf(nk, NK_TEXT_LEFT, "Detail: %s", st->problem.detail);
    if (st->problem.trace_id[0] != '\0') nk_labelf(nk, NK_TEXT_LEFT, "Trace id: %s", st->problem.trace_id);
    for (int i = 0; i < st->problem.field_count; i++) {
        nk_labelf(nk, NK_TEXT_LEFT, "Field %s: %s", st->problem.fields[i].pointer, st->problem.fields[i].detail);
    }
    if (nk_button_label(nk, "Dismiss")) ts_store_dismiss_problem(st);
}

void ts_ui_frame(struct nk_context *nk, ts_store *st, float w, float h) {
    if (nk_begin(nk, "Tasks and Teams", nk_rect(0, 0, w, h), NK_WINDOW_NO_SCROLLBAR)) {
        nk_layout_row_dynamic(nk, 36, 1);
        nk_label(nk, "Tasks and Teams: connection check", NK_TEXT_LEFT);

        nk_layout_row_dynamic(nk, 26, 1);
        nk_labelf(nk, NK_TEXT_LEFT, "API base: %s", st->cfg.api_base);
        nk_labelf(nk, NK_TEXT_LEFT, "Frames drawn: %lu (the window never freezes)", st->frames);

        nk_layout_row_dynamic(nk, 34, 2);
        if (nk_button_label(nk, "Test connection (GET /health)")) ts_store_check_health(st);
        if (nk_button_label(nk, "Call GET /v1/me without a token")) ts_store_call_me(st);

        nk_layout_row_dynamic(nk, 26, 1);
        if (ts_store_busy(st)) nk_label(nk, "Working...", NK_TEXT_LEFT);
        if (st->have_health) {
            nk_labelf(nk, NK_TEXT_LEFT, "Health: status %s, database %s, version %s", st->health.status,
                      st->health.database, st->health.version);
        }
        if (st->has_problem) problem_panel(nk, st);
    }
    nk_end(nk);
}
