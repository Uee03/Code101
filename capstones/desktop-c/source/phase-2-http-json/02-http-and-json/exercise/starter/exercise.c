#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

/* Percent-encode s into out (capacity cap, terminator included).
   Keep A-Z a-z 0-9 - . _ ~ as they are; write every other byte as %XX with capital hex digits.
   Return true only when everything fits; on failure out must be "". */
static bool url_encode(const char *s, char *out, size_t cap) {
    static const char hex[] = "0123456789ABCDEF";
    /* TODO 1: reject out == NULL, cap == 0 or s == NULL; make out an empty string first. */
    /* TODO 2: loop over the bytes of s (use unsigned char). Before each write, check that
               enough room is left for the bytes you are about to write plus the terminator. */
    /* TODO 3: write the terminator and return true. On "no room": out[0] = '\0', return false. */
    (void)hex;
    (void)s;
    (void)out;
    (void)cap;
    return false;
}

static void show(const char *label, const char *input, size_t cap) {
    char buf[32] = "";
    if (cap > sizeof buf) cap = sizeof buf;
    if (url_encode(input, buf, cap)) {
        printf("%s: %s\n", label, buf);
    } else {
        printf("%s: rejected (%zu bytes of room), out is \"%s\"\n", label, cap, buf);
    }
}

int main(void) {
    show("plain", "a b&c", 32);
    show("utf8", "\xC3\xA9", 32);
    show("tight", "a b&c", 5);
    return 0;
}
