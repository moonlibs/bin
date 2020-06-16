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

uint8_t reb_decode(const char *p, size_t size, uint64_t * result) {
	uint8_t byte;
	for (byte = 0; byte < 10; byte++) {
		if (size <= byte) {
			// Fail case: you cannot unpack 0 bytes
			return 0;
		}
		*result += ((uint64_t) p[byte] & 0x7f) << (byte * 7);
		if (byte < 9) {
			// if most significant bit is 0
			if (!(p[byte] & 0x80)) {
				// return amount of consumed bytes
				return byte+1;
			}
		} else if (p[byte] != 0x01) {
			// 10-th byte of REB number must always equals 0x01
			return 0;
		}
	}
	// At this poing byte always equal 10
	return byte;
}

uint8_t reb_encode(uint64_t n, char *buf, size_t size) {
	if (n <= 0x7f) {
		*buf = (char) n;
	} else {
		char *ptr = buf, *pend = buf + size;
		for (; n && ptr <= pend; n >>= 7, ptr++) {
			*ptr = (n & 0x7f) | ( n > 0x7f ? 0x80 : 0 );
		}
		if (ptr > pend) {
			return 1; // fail
		}
		if (n > 0) {
			return 1; // fail, number wasn't packed
		}
	}
	return 0;
}
