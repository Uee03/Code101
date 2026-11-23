#include <errno.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* The API sends the version of a task as a strong ETag: the decimal number in double quotes, such as "3".
   Parse it into *out. Accept only a quoted run of digits whose value is at least 1 and fits in a long.
   Return false for everything else (no quotes, weak "W/" prefix, empty, letters, spaces, a sign, overflow, zero),
   and leave *out untouched in that case. */
static bool parse_etag_version(const char *etag, long *out) {
    if (etag == NULL || out == NULL) return false;
    size_t n = strlen(etag);
    if (n < 3 || etag[0] != '"' || etag[n - 1] != '"') return false;

    char digits[24];
    size_t len = n - 2;
    if (len >= sizeof digits) return false;
    memcpy(digits, etag + 1, len);
    digits[len] = '\0';
    for (size_t i = 0; i < len; i++) {
        if (digits[i] < '0' || digits[i] > '9') return false;
    }

    errno = 0;
    char *end = NULL;
    long value = strtol(digits, &end, 10);
    if (errno == ERANGE || end == digits || *end != '\0' || value < 1) return false;
    *out = value;
    return true;
}

static void show(const char *etag) {
    long version = 0;
    printf("%s -> ", etag);
    if (parse_etag_version(etag, &version)) {
        printf("%ld\n", version);
    } else {
        printf("rejected\n");
    }
}

int main(void) {
    show("\"3\"");
    show("3");
    show("\"\"");
    show("\"12abc\"");
    show("\"99999999999999999999\"");
    show("\"0\"");
    show("W/\"3\"");
    return 0;
}
