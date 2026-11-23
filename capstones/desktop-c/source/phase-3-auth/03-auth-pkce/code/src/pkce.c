#include "pkce.h"

#include <limits.h>
#include <openssl/evp.h>
#include <openssl/rand.h>
#include <string.h>

#include "util.h"

bool ts_random_bytes(void *out, size_t n) {
    if (n == 0 || n > INT_MAX) return false;
    return RAND_bytes(out, (int)n) == 1;
}

bool ts_sha256(const void *data, size_t n, unsigned char out[32]) {
    unsigned int len = 0;
    return EVP_Digest(data, n, out, &len, EVP_sha256(), NULL) == 1 && len == 32;
}

size_t ts_base64url(const void *data, size_t n, char *out, size_t cap) {
    static const char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    const unsigned char *in = data;
    if (n == 0 || out == NULL) return 0;
    size_t full = n / 3;
    size_t rest = n % 3;
    size_t need = full * 4 + (rest == 0 ? 0 : rest + 1);
    if (full > (SIZE_MAX - 2) / 4 || cap < need + 1) return 0;

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

bool ts_random_uuid(char out[37]) {
    unsigned char b[16];
    if (!ts_random_bytes(b, sizeof b)) return false;
    b[6] = (unsigned char)((b[6] & 0x0F) | 0x40); /* version 4 */
    b[8] = (unsigned char)((b[8] & 0x3F) | 0x80); /* variant 10 */
    return ts_setf(out, 37, "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", b[0], b[1], b[2],
                   b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]);
}

bool ts_pkce_new(ts_pkce *p) {
    unsigned char verifier_bytes[32];
    unsigned char state_bytes[24];
    unsigned char digest[32];

    memset(p, 0, sizeof *p);
    bool ok = ts_random_bytes(verifier_bytes, sizeof verifier_bytes) &&
              ts_base64url(verifier_bytes, sizeof verifier_bytes, p->verifier, sizeof p->verifier) > 0 &&
              ts_sha256(p->verifier, strlen(p->verifier), digest) &&
              ts_base64url(digest, sizeof digest, p->challenge, sizeof p->challenge) > 0 &&
              ts_random_bytes(state_bytes, sizeof state_bytes) &&
              ts_base64url(state_bytes, sizeof state_bytes, p->state, sizeof p->state) > 0;

    ts_secure_zero(verifier_bytes, sizeof verifier_bytes);
    ts_secure_zero(state_bytes, sizeof state_bytes);
    ts_secure_zero(digest, sizeof digest);
    if (!ok) ts_secure_zero(p, sizeof *p);
    return ok;
}
