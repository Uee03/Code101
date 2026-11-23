#include "ui.h"

/* Draws the last problem and returns the height it used, so the columns below can use the rest. */
static float problem_panel(struct nk_context *nk, ts_store *st) {
    int rows = 2 + (st->problem.detail[0] != '\0') + (st->problem.trace_id[0] != '\0') + st->problem.field_count;
    nk_layout_row_dynamic(nk, 52, 1);
    nk_label_wrap(nk, st->message);
    nk_layout_row_dynamic(nk, 26, 1);
    if (st->problem.detail[0] != '\0') nk_labelf(nk, NK_TEXT_LEFT, "Detail: %s", st->problem.detail);
    if (st->problem.trace_id[0] != '\0') nk_labelf(nk, NK_TEXT_LEFT, "Trace id: %s", st->problem.trace_id);
    for (int i = 0; i < st->problem.field_count; i++) {
        nk_labelf(nk, NK_TEXT_LEFT, "Field %s: %s", st->problem.fields[i].pointer, st->problem.fields[i].detail);
    }
    if (nk_button_label(nk, "Dismiss")) ts_store_dismiss_problem(st);
    return 52.0f + 30.0f * (float)(rows - 1);
}

static void signed_out_panel(struct nk_context *nk, ts_store *st) {
    nk_layout_row_dynamic(nk, 36, 1);
    nk_label(nk, "Tasks and Teams", NK_TEXT_LEFT);
    nk_layout_row_dynamic(nk, 26, 1);
    nk_labelf(nk, NK_TEXT_LEFT, "API base: %s", st->cfg.api_base);
    nk_labelf(nk, NK_TEXT_LEFT, "Issuer: %s (client %s)", st->cfg.issuer, st->cfg.client_id);

    switch (st->auth_state) {
    case TS_AUTH_SIGNED_OUT:
        nk_label(nk, "You are signed out.", NK_TEXT_LEFT);
        if (st->login_message[0] != '\0') {
            nk_layout_row_dynamic(nk, 52, 1);
            nk_label_wrap(nk, st->login_message);
        }
        nk_layout_row_dynamic(nk, 34, 2);
        if (nk_button_label(nk, "Sign in with the browser")) ts_store_sign_in(st);
        if (nk_button_label(nk, "Test connection (GET /health)")) ts_store_check_health(st);
        break;
    case TS_AUTH_STARTING:
        nk_label(nk, "Contacting the identity server...", NK_TEXT_LEFT);
        break;
    case TS_AUTH_WAITING:
        nk_label(nk, "Waiting for you to finish in the browser.", NK_TEXT_LEFT);
        nk_labelf(nk, NK_TEXT_LEFT, "Listening for the answer on %s", st->auth.redirect_uri);
        nk_layout_row_dynamic(nk, 34, 2);
        if (nk_button_label(nk, "Cancel")) ts_store_cancel_sign_in(st);
        if (nk_button_label(nk, "Copy the sign-in address")) SDL_SetClipboardText(st->sign_in_url);
        break;
    case TS_AUTH_EXCHANGING:
        nk_label(nk, "Finishing the sign-in...", NK_TEXT_LEFT);
        break;
    case TS_AUTH_SIGNED_IN:
        break;
    }
    nk_layout_row_dynamic(nk, 26, 1);
    if (st->have_health) {
        nk_labelf(nk, NK_TEXT_LEFT, "Health: status %s, database %s, version %s", st->health.status,
                  st->health.database, st->health.version);
    }
}

static void header(struct nk_context *nk, ts_store *st) {
    static const float ratio[3] = {0.62f, 0.14f, 0.24f};
    nk_layout_row(nk, NK_DYNAMIC, 34, 3, ratio);
    nk_labelf(nk, NK_TEXT_LEFT, "Tasks and Teams    %s (%s), roles: %s", st->me.display_name, st->me.username,
              st->me.roles);
    nk_label(nk, ts_store_busy(st) ? "Working..." : "", NK_TEXT_LEFT);
    if (nk_button_label(nk, "Sign out")) ts_store_sign_out(st);
}

void ts_ui_frame(struct nk_context *nk, ts_store *st, float w, float h) {
    if (nk_begin(nk, "Tasks and Teams", nk_rect(0, 0, w, h), NK_WINDOW_NO_SCROLLBAR)) {
        float used = 0.0f;
        if (st->auth_state == TS_AUTH_SIGNED_IN) {
            header(nk, st);
            used += 42.0f;
        } else {
            signed_out_panel(nk, st);
            used += 300.0f; /* generous: this branch has no columns to size */
        }
        if (st->info[0] != '\0') {
            nk_layout_row_dynamic(nk, 26, 1);
            nk_label(nk, st->info, NK_TEXT_LEFT);
            used += 30.0f;
        }
        if (st->has_problem) used += problem_panel(nk, st);
        if (st->auth_state == TS_AUTH_SIGNED_IN) {
            float body = h - used - 24.0f;
            ts_ui_workspace(nk, st, body < 200.0f ? 200.0f : body);
        }
    }
    nk_end(nk);
}
