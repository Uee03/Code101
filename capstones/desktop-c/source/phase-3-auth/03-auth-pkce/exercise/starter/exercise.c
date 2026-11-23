#include <stdint.h>
#include <stdio.h>
#include <string.h>

/* Base64url without padding (RFC 4648 section 5): the alphabet A-Z a-z 0-9 - _
   Return the number of characters written (out is NUL-terminated), or 0 when n is 0 or
   cap is too small for the text plus the terminator. Never write past out[cap - 1]. */
static size_t base64url(const unsigned char *in, size_t n, char *out, size_t cap) {
    static const char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    /* TODO 1: if n == 0 or out == NULL return 0. Work out how many characters are needed:
               4 per full group of 3 bytes, plus 2 for one left-over byte or 3 for two left-over bytes. */
    /* TODO 2: if cap < needed + 1 return 0 (before writing anything). */
    /* TODO 3: loop over full groups: v = (in[i] << 16) | (in[i+1] << 8) | in[i+2];
               write alphabet[(v >> 18) & 63], alphabet[(v >> 12) & 63], alphabet[(v >> 6) & 63], alphabet[v & 63]. */
    /* TODO 4: handle the 1 or 2 left-over bytes the same way but write only 2 or 3 characters. */
    (void)alphabet;
    (void)in;
    (void)n;
    (void)out;
    (void)cap;
    return 0;
}

static void show(const char *label, const unsigned char *in, size_t n, size_t cap) {
    char out[16] = "";
    if (cap > sizeof out) cap = sizeof out;
    size_t len = base64url(in, n, out, cap);
    if (len == 0) {
        printf("%s -> 0\n", label);
    } else {
        printf("%s -> %s\n", label, out);
    }
}

int main(void) {
    const unsigned char man[] = {'M', 'a', 'n'};
    const unsigned char ma[] = {'M', 'a'};
    const unsigned char m[] = {'M'};
    const unsigned char ff[] = {0xFB, 0xFF};

    show("Man", man, 3, 16);
    show("Ma", ma, 2, 16);
    show("M", m, 1, 16);
    show("fb ff", ff, 2, 16);
    show("tight buffer", man, 3, 3);
    return 0;
}
