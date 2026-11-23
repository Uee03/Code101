#include "ui.h"

void ts_ui_frame(struct nk_context *nk, ts_store *st, float w, float h) {
    if (nk_begin(nk, "Tasks and Teams", nk_rect(0, 0, w, h), NK_WINDOW_NO_SCROLLBAR)) {
        nk_layout_row_dynamic(nk, 36, 1);
        nk_label(nk, "Tasks and Teams: desktop client", NK_TEXT_LEFT);

        nk_layout_row_dynamic(nk, 26, 1);
        nk_labelf(nk, NK_TEXT_LEFT, "API base: %s", st->cfg.api_base);
        nk_labelf(nk, NK_TEXT_LEFT, "Issuer: %s", st->cfg.issuer);
        nk_labelf(nk, NK_TEXT_LEFT, "Client id: %s", st->cfg.client_id);
        nk_labelf(nk, NK_TEXT_LEFT, "Frames drawn: %lu", st->frames);

        nk_label(nk, "Keyboard test (at most 63 bytes fit):", NK_TEXT_LEFT);
        nk_edit_string_zero_terminated(nk, NK_EDIT_FIELD, st->echo, (int)sizeof st->echo, nk_filter_default);
        nk_labelf(nk, NK_TEXT_LEFT, "You typed: %s", st->echo);
    }
    nk_end(nk);
}
