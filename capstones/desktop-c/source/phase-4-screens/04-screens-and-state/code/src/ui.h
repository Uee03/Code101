#ifndef TS_UI_H
#define TS_UI_H

#include "nk_api.h"
#include "store.h"

/* Builds the whole UI for one frame. w and h are the logical window size. */
void ts_ui_frame(struct nk_context *nk, ts_store *st, float w, float h);

/* The three columns shown while signed in (ui_work.c). body_h is the height left for them. */
void ts_ui_workspace(struct nk_context *nk, ts_store *st, float body_h);

#endif
