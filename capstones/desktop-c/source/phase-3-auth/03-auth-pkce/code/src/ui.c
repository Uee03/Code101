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

static void account_panel(struct nk_context *nk, ts_store *st) {
    nk_layout_row_dynamic(nk, 28, 1);
    nk_label(nk, "Account", NK_TEXT_LEFT);
    nk_layout_row_dynamic(nk, 26, 1);

    switch (st->auth_state) {
    case TS_AUTH_SIGNED_OUT:
        nk_label(nk, "You are signed out.", NK_TEXT_LEFT);
        if (st->login_message[0] != '\0') {
            nk_layout_row_dynamic(nk, 52, 1);
            nk_label_wrap(nk, st->login_message);
        }
        nk_layout_row_dynamic(nk, 34, 2);
        if (nk_button_label(nk, "Sign in with the browser")) ts_store_sign_in(st);
        nk_spacing(nk, 1);
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
        nk_labelf(nk, NK_TEXT_LEFT, "Signed in as %s (%s), roles: %s", st->me.display_name, st->me.username, st->me.roles);
        nk_layout_row_dynamic(nk, 34, 2);
        if (nk_button_label(nk, "Ask GET /v1/me again")) ts_store_call_me(st);
        if (nk_button_label(nk, "Sign out")) ts_store_sign_out(st);
        break;
    }
}

void ts_ui_frame(struct nk_context *nk, ts_store *st, float w, float h) {
    if (nk_begin(nk, "Tasks and Teams", nk_rect(0, 0, w, h), NK_WINDOW_NO_SCROLLBAR)) {
        nk_layout_row_dynamic(nk, 36, 1);
        nk_label(nk, "Tasks and Teams: sign-in check", NK_TEXT_LEFT);

        nk_layout_row_dynamic(nk, 26, 1);
        nk_labelf(nk, NK_TEXT_LEFT, "API base: %s", st->cfg.api_base);
        nk_labelf(nk, NK_TEXT_LEFT, "Issuer: %s (client %s)", st->cfg.issuer, st->cfg.client_id);
        nk_labelf(nk, NK_TEXT_LEFT, "Frames drawn: %lu", st->frames);

        account_panel(nk, st);

        nk_layout_row_dynamic(nk, 34, 1);
        if (nk_button_label(nk, "Test connection (GET /health)")) ts_store_check_health(st);

        nk_layout_row_dynamic(nk, 26, 1);
        if (ts_store_busy(st)) nk_label(nk, "Working...", NK_TEXT_LEFT);
        if (st->have_health) {
            nk_labelf(nk, NK_TEXT_LEFT, "Health: status %s, database %s, version %s", st->health.status,
                      st->health.database, st->health.version);
        }
        if (st->info[0] != '\0') nk_label(nk, st->info, NK_TEXT_LEFT);
        if (st->has_problem) problem_panel(nk, st);
    }
    nk_end(nk);
}
