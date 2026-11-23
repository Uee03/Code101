#include <stdbool.h>
#include <stdio.h>
#include <string.h>

/* Join dir and file with one '/'.
   Return true only when the whole result fits in dst (capacity cap, terminator included).
   On any failure dst must be left as an empty string, never as cut-off text. */
static bool join_path(char *dst, size_t cap, const char *dir, const char *file) {
    /* TODO 1: reject dst == NULL or cap == 0 (nothing can be written). */
    /* TODO 2: make dst an empty string, then reject dir == NULL or file == NULL. */
    /* TODO 3: call snprintf(dst, cap, "%s/%s", dir, file) and keep its return value. */
    /* TODO 4: a negative value, or a value >= cap, means the text did not fit:
               set dst[0] = '\0' and return false. */
    (void)dst;
    (void)cap;
    (void)dir;
    (void)file;
    return false;
}

int main(void) {
    char big[16];
    char small[8] = "x";

    if (join_path(big, sizeof big, "api", "tasks")) {
        printf("join ok: %s\n", big);
    } else {
        printf("join failed\n");
    }

    if (!join_path(small, sizeof small, "api", "tasks") && small[0] == '\0') {
        printf("join too long: rejected, dst is empty\n");
    } else {
        printf("BUG: truncated text accepted\n");
    }
    return 0;
}
