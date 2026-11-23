#include <stdint.h>
#include <stdio.h>
#include <string.h>

/* Base64url without padding (RFC 4648 section 5): the alphabet A-Z a-z 0-9 - _
   Return the number of characters written (out is NUL-terminated), or 0 when n is 0 or
   cap is too small for the text plus the terminator. Never write past out[cap - 1]. */
static size_t base64url(const unsigned char *in, size_t n, char *out, size_t cap) {
    static const char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    if (n == 0 || out == NULL) return 0;
    size_t full = n / 3;
    size_t rest = n % 3;
    size_t needed = full * 4 + (rest == 0 ? 0 : rest + 1);
    if (cap < needed + 1) return 0;

    size_t o = 0;
    for (size_t i = 0; i < full * 3; i += 3) {
        uint32_t v = ((uint32_t)in[i] << 16) | ((uint32_t)in[i + 1] << 8) | in[i + 2];
        out[o++] = alphabet[(v >> 18) & 63];
        out[o++] = alphabet[(v >> 12) & 63];
        out[o++] = alphabet[(v >> 6) & 63];
        out[o++] = alphabet[v & 63];
    }
    if (rest == 1) {
        uint32_t v = (uint32_t)in[n - 1] << 16;
        out[o++] = alphabet[(v >> 18) & 63];
        out[o++] = alphabet[(v >> 12) & 63];
    } else if (rest == 2) {
        uint32_t v = ((uint32_t)in[n - 2] << 16) | ((uint32_t)in[n - 1] << 8);
        out[o++] = alphabet[(v >> 18) & 63];
        out[o++] = alphabet[(v >> 12) & 63];
        out[o++] = alphabet[(v >> 6) & 63];
    }
    out[o] = '\0';
    return o;
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
