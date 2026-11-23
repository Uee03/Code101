#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* A tiny counted allocator, like ts_malloc and ts_free in the app, with a switch that makes it fail on purpose. */
static long live = 0;
static int allocs_until_failure = -1; /* -1 = never fail */

static void *xalloc(size_t n) {
    if (allocs_until_failure == 0) return NULL;
    if (allocs_until_failure > 0) allocs_until_failure--;
    void *p = malloc(n);
    if (p != NULL) live++;
    return p;
}

static void xfree(void *p) {
    if (p == NULL) return;
    live--;
    free(p);
}

static char *xdup(const char *s) {
    size_t n = strlen(s) + 1;
    char *p = xalloc(n);
    if (p != NULL) memcpy(p, s, n);
    return p;
}

typedef struct {
    char *name; /* owned */
    char *note; /* owned */
} entry;

static void entry_free(entry *e) {
    if (e == NULL) return;
    xfree(e->name);
    xfree(e->note);
    xfree(e);
}

/* BUG 1: when one of the copies fails, what was already allocated is never released. */
static entry *entry_new(const char *name, const char *note) {
    entry *e = xalloc(sizeof *e);
    if (e == NULL) return NULL;
    e->name = xdup(name);
    e->note = xdup(note);
    if (e->name == NULL || e->note == NULL) return NULL;
    return e;
}

/* Hands the name to the caller, who frees it. BUG 2: the entry still points at it afterwards. */
static char *take_name(entry *e) {
    return e->name;
}

/* BUG 3: the old note is lost without being freed, and a failed copy would clobber the pointer. */
static bool replace_note(entry *e, const char *note) {
    e->note = xdup(note);
    return e->note != NULL;
}

int main(void) {
    entry *e = entry_new("alice", "first");
    char *name = take_name(e);
    printf("name taken: %s\n", name);
    replace_note(e, "second");
    printf("note replaced: %s\n", e->note);
    xfree(name);
    entry_free(e);
    printf("after normal use, outstanding: %ld\n", live);

    allocs_until_failure = 2; /* the entry and its name succeed, the note fails */
    e = entry_new("bob", "x");
    printf("%s\n", e == NULL ? "entry_new with a failing allocation returned NULL" : "entry_new unexpectedly succeeded");
    entry_free(e);
    printf("after failed entry_new, outstanding: %ld\n", live);
    return 0;
}
