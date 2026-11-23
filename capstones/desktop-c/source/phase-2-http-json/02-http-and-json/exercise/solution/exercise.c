#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

/* Percent-encode s into out (capacity cap, terminator included).
   Keep A-Z a-z 0-9 - . _ ~ as they are; write every other byte as %XX with capital hex digits.
   Return true only when everything fits; on failure out must be "". */
static bool url_encode(const char *s, char *out, size_t cap) {
    static const char hex[] = "0123456789ABCDEF";
    if (out == NULL || cap == 0) return false;
    out[0] = '\0';
    if (s == NULL) return false;

    size_t o = 0;
    for (const unsigned char *p = (const unsigned char *)s; *p != '\0'; p++) {
        bool keep = isalnum(*p) || *p == '-' || *p == '.' || *p == '_' || *p == '~';
        size_t need = keep ? 1 : 3;
        if (need > cap - 1 - o) { /* cap - 1 - o never wraps: o <= cap - 1 here */
            out[0] = '\0';
            return false;
        }
        if (keep) {
            out[o++] = (char)*p;
        } else {
            out[o++] = '%';
            out[o++] = hex[*p >> 4];
            out[o++] = hex[*p & 15];
        }
    }
    out[o] = '\0';
    return true;
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
