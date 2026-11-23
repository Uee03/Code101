#include <stdbool.h>
#include <stdio.h>
#include <string.h>

/* Join dir and file with one '/'.
   Return true only when the whole result fits in dst (capacity cap, terminator included).
   On any failure dst must be left as an empty string, never as cut-off text. */
static bool join_path(char *dst, size_t cap, const char *dir, const char *file) {
    if (dst == NULL || cap == 0) return false;
    dst[0] = '\0';
    if (dir == NULL || file == NULL) return false;
    int n = snprintf(dst, cap, "%s/%s", dir, file);
    if (n < 0 || (size_t)n >= cap) {
        dst[0] = '\0';
        return false;
    }
    return true;
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
