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

/* Fixed: entry_free releases whatever was allocated so far (xfree(NULL) is allowed). */
static entry *entry_new(const char *name, const char *note) {
    entry *e = xalloc(sizeof *e);
    if (e == NULL) return NULL;
    e->name = xdup(name);
    e->note = xdup(note);
    if (e->name == NULL || e->note == NULL) {
        entry_free(e);
        return NULL;
    }
    return e;
}

/* Fixed: ownership moves to the caller, so the entry forgets the pointer. */
static char *take_name(entry *e) {
    char *name = e->name;
    e->name = NULL;
    return name;
}

/* Fixed: copy first, then free the old note and keep the new one; on failure nothing changes. */
static bool replace_note(entry *e, const char *note) {
    char *copy = xdup(note);
    if (copy == NULL) return false;
    xfree(e->note);
    e->note = copy;
    return true;
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
