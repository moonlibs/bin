---
-- This module contains basic binary functions.
-- @release v4
-- @module bin.base
local M = { V = 4 }

local ffi = require 'ffi.reloadable'
local so_lib_path do
	local so_lib_name = 'libluabin-scm-'..M.V
	if package.search then
		so_lib_path = package.search(so_lib_name)
	else
		so_lib_path = package.searchpath(so_lib_name, package.cpath)
	end
	assert(so_lib_path, "bin: failed to find "..so_lib_name)
end
local lib = ffi.load(so_lib_path, true)

ffi.fundef('calloc',  [[ void *calloc(size_t count, size_t size); ]])
ffi.fundef('malloc',  [[ void * malloc(size_t size); ]])
ffi.fundef('realloc', [[ void * realloc(void *ptr, size_t size); ]])
ffi.fundef('free',    [[ void free(void *ptr); ]])
ffi.fundef('memmove', [[ void * memmove(void *dst, const void *src, size_t len); ]])

ffi.fundef('reb_decode',[[
	uint8_t reb_decode(const char *p, size_t size, uint64_t * result);
]])
ffi.fundef('reb_encode',[[
	uint8_t reb_encode(uint64_t n, char *buf, size_t size);
]])
ffi.fundef('bin_hex',[[
	char * bin_hex(unsigned char *p, size_t size);
]])
ffi.typedef('xd_conf',[[
	typedef struct {
		uint8_t row;
		uint8_t hpad;
		uint8_t cpad;
		uint8_t hsp;
		uint8_t csp;
		uint8_t cols;
	} xd_conf;
]]);
ffi.fundef('bin_xd',[[
	char * bin_xd(const char *data, size_t size, xd_conf *cf);
]])

ffi.fundef('bin_htobe16',[[uint16_t bin_htobe16 (uint16_t x);]])
---
-- Converts host byte order to big endian 16 bits.
-- @param x number
function M.htobe16(x) return lib.bin_htobe16(x) end
ffi.fundef('bin_htole16',[[uint16_t bin_htole16 (uint16_t x);]])
---
-- Converts host byte order to little endian 16 bits.
-- @param x number
function M.htole16(x) return lib.bin_htole16(x) end
ffi.fundef('bin_be16toh',[[uint16_t bin_be16toh (uint16_t x);]])
---
-- Converts big endian 16 bits to host byte order.
-- @param x number
function M.be16toh(x) return lib.bin_be16toh(x) end
ffi.fundef('bin_le16toh',[[uint16_t bin_le16toh (uint16_t x);]])
---
-- Converts little endian 16 bits to host byte
-- @param x number
function M.le16toh(x) return lib.bin_le16toh(x) end
ffi.fundef('bin_htobe32',[[uint32_t bin_htobe32 (uint32_t x);]])
---
-- Converts host byte order to big endian 32 bits.
-- @param x number
function M.htobe32(x) return lib.bin_htobe32(x) end
ffi.fundef('bin_htole32',[[uint32_t bin_htole32 (uint32_t x);]])
---
-- Converts host byte order to little endian 32 bits.
-- @param x number
function M.htole32(x) return lib.bin_htole32(x) end
ffi.fundef('bin_be32toh',[[uint32_t bin_be32toh (uint32_t x);]])
---
-- Converts big endian 32 bits to host byte order.
-- @param x number
function M.be32toh(x) return lib.bin_be32toh(x) end
ffi.fundef('bin_le32toh',[[uint32_t bin_le32toh (uint32_t x);]])
---
-- Converts little endian 32 bits to host byte
-- @param x number
function M.le32toh(x) return lib.bin_le32toh(x) end
ffi.fundef('bin_htobe64',[[uint64_t bin_htobe64 (uint64_t x);]])
---
-- Converts host byte order to big endian 64 bits.
-- @param x number
function M.htobe64(x) return lib.bin_htobe64(x) end
ffi.fundef('bin_htole64',[[uint64_t bin_htole64 (uint64_t x);]])
---
-- Converts host byte order to little endian 64 bits.
-- @param x number
function M.htole64(x) return lib.bin_htole64(x) end
ffi.fundef('bin_be64toh',[[uint64_t bin_be64toh (uint64_t x);]])
---
-- Converts big endian 64 bits to host byte order.
-- @param x number
function M.be64toh(x) return lib.bin_be64toh(x) end
ffi.fundef('bin_le64toh',[[uint64_t bin_le64toh (uint64_t x);]])
---
-- Converts little endian 64 bits to host byte
-- @param x number
function M.le64toh(x) return lib.bin_le64toh(x) end

M.jit_major = require 'jit'.version_num

if not rawget(_G, 'dostring') then
	if not rawget(_G, 'loadstring') then
		rawset(_G, 'loadstring', load)
	end
	local loadstring = rawget(_G, 'loadstring')
	rawset(_G, 'dostring', function(str) return assert(loadstring(str))() end)
end

---
-- Returns hex representation of the binary data
-- @param data accepts string, allmost any pointer - start of the data.
-- @param len length of the data in bytes
-- @treturn string `hex` representation of the data
-- @usage
-- print(bin.hex "some binary string")
-- 736F6D652062696E61727920737472696E67
function M.hex(data, len)
	len = len or #data
	local buf = lib.bin_hex(ffi.cast("char*",data),len);
	local rv
	if buf then
		rv = ffi.string(buf)
		lib.free(buf)
	else
		error("Failed")
	end
	return rv
end

---
-- Returns hexdump (hexdump -C) of the binary data
-- @param data accepts string, allmost any pointer - start of the data.
-- @param len length of the data in bytes
-- @treturn string `hexdump` representation of the data
-- @usage
-- print(bin.xd "some binary string")
-- [0000]   73 6F 6D 65  20 62 69 6E  61 72 79 20  73 74 72 69   some  bin ary  stri
-- [0010]   6E 67                                                ng
function M.xd(data, len)
	len = len or #data
	local buf = lib.bin_xd(ffi.cast("char*",data),len,nil);
	local rv
	if buf then
		rv = ffi.string(buf)
		lib.free(buf)
	else
		error("Failed")
	end
	return rv
end

return M
