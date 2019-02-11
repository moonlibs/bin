#include <stdlib.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <sys/types.h>
#include <string.h>
#include <stdio.h>

#include "portable_endian.h"
#include "xd.h"

char * bin_xd(char *data, size_t size, xd_conf *cf) {
	return xd(data, size, cf);
}

uint16_t bin_htobe16 (uint16_t x) { return htobe16(x); }
uint16_t bin_htole16 (uint16_t x) {	return htole16(x); }
uint16_t bin_be16toh (uint16_t x) { return be16toh(x); }
uint16_t bin_le16toh (uint16_t x) {	return le16toh(x); }

uint32_t bin_htobe32 (uint32_t x) { return htobe32(x); }
uint32_t bin_htole32 (uint32_t x) {	return htole32(x); }
uint32_t bin_be32toh (uint32_t x) { return be32toh(x); }
uint32_t bin_le32toh (uint32_t x) {	return le32toh(x); }

uint64_t bin_htobe64 (uint64_t x) { return htobe64(x); }
uint64_t bin_htole64 (uint64_t x) {	return htole64(x); }
uint64_t bin_be64toh (uint64_t x) { return be64toh(x); }
uint64_t bin_le64toh (uint64_t x) {	return le64toh(x); }

char * bin_hex(unsigned char *p, size_t size) {
	char *rv = malloc(size*2+1);
	char *r = rv;
	if (!rv) {
		fprintf(stderr,"Can't allocate memory\n");
		return NULL;
	}
	unsigned char * e = p + size;
	for (; p<e; p++) {
		snprintf(rv, 3, "%02X", *p);
		rv+=2;
	}
	*rv = 0;
	return r;
}

uint8_t reb_decode(unsigned char *p, uint64_t * result) {
	uint8_t i;
	for (i = 0; i < 10; i++) {
		*result += ((uint64_t) p[i] & 0x7f) << (i * 7);
		if (!(p[i] & 0x80)) {
			return i + 1;
		}
	}
	return i;
}

void reb_encode(uint64_t n, char *buf) {
	if (n <= 0x7f) {
		*buf = (char) n;
	} else {
		char *ptr = buf;
		while(n) {
			*ptr++ = (n & 0x7f) | ( n > 0x7f ? 0x80 : 0 );
			n >>= 7;
		}
	}
	return;
}
