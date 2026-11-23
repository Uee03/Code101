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
    /* TODO 1: reject NULL arguments. */
    /* TODO 2: the text must be at least 3 characters and start and end with '"'. */
    /* TODO 3: copy the characters between the quotes into a small buffer (reject if too long for it)
               and check that every one of them is '0' to '9'. */
    /* TODO 4: call strtol with errno = 0 first; reject ERANGE, "no digits", leftover text and values below 1. */
    (void)etag;
    (void)out;
    (void)errno;
    return false;
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
