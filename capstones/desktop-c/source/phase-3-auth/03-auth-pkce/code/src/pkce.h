#ifndef TS_PKCE_H
#define TS_PKCE_H

#include <stdbool.h>
#include <stddef.h>

/* Fills out with n bytes from the operating system's cryptographic generator (via OpenSSL). */
bool ts_random_bytes(void *out, size_t n);
bool ts_sha256(const void *data, size_t n, unsigned char out[32]);

/* Base64url without padding (RFC 4648 section 5). Returns the number of characters written
   (the text is NUL-terminated), or 0 when n is 0 or cap is too small. */
size_t ts_base64url(const void *data, size_t n, char *out, size_t cap);

/* A random version 4 UUID in text form (36 characters plus the terminator). */
bool ts_random_uuid(char out[37]);

/* The three secrets of one sign-in attempt (RFC 7636 and RFC 6749). */
typedef struct {
    char verifier[64];  /* 43 characters: base64url of 32 random bytes */
    char challenge[48]; /* base64url of SHA-256(verifier) */
    char state[48];     /* 32 characters: base64url of 24 random bytes */
} ts_pkce;

bool ts_pkce_new(ts_pkce *p);

#endif
