#include "store.h"

#include <string.h>

bool ts_store_init(ts_store *st) {
    memset(st, 0, sizeof *st);
    ts_config_load(&st->cfg);
    return true;
}

void ts_store_pump(ts_store *st) {
    st->frames++;
}

void ts_store_shutdown(ts_store *st) {
    (void)st;
}
