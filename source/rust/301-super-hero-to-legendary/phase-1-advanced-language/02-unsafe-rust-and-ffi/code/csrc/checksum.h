#ifndef C101_CHECKSUM_H
#define C101_CHECKSUM_H

#include <stddef.h>
#include <stdint.h>

/* Adler-32 of len bytes at data. data may be NULL only when len is 0. */
uint32_t c101_checksum(const uint8_t *data, size_t len);

#endif
