local M = { V = 3 }

local ffi = require 'ffi.reloadable'
local lib = ffi.load(package.searchpath('libluabin-scm-'..M.V, package.cpath), true)

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

-- endian
ffi.fundef('bin_htobe16',[[uint16_t bin_htobe16 (uint16_t x);]]) function M.htobe16(x) return lib.bin_htobe16(x) end
ffi.fundef('bin_htole16',[[uint16_t bin_htole16 (uint16_t x);]]) function M.htole16(x) return lib.bin_htole16(x) end
ffi.fundef('bin_be16toh',[[uint16_t bin_be16toh (uint16_t x);]]) function M.be16toh(x) return lib.bin_be16toh(x) end
ffi.fundef('bin_le16toh',[[uint16_t bin_le16toh (uint16_t x);]]) function M.le16toh(x) return lib.bin_le16toh(x) end
ffi.fundef('bin_htobe32',[[uint32_t bin_htobe32 (uint32_t x);]]) function M.htobe32(x) return lib.bin_htobe32(x) end
ffi.fundef('bin_htole32',[[uint32_t bin_htole32 (uint32_t x);]]) function M.htole32(x) return lib.bin_htole32(x) end
ffi.fundef('bin_be32toh',[[uint32_t bin_be32toh (uint32_t x);]]) function M.be32toh(x) return lib.bin_be32toh(x) end
ffi.fundef('bin_le32toh',[[uint32_t bin_le32toh (uint32_t x);]]) function M.le32toh(x) return lib.bin_le32toh(x) end
ffi.fundef('bin_htobe64',[[uint64_t bin_htobe64 (uint64_t x);]]) function M.htobe64(x) return lib.bin_htobe64(x) end
ffi.fundef('bin_htole64',[[uint64_t bin_htole64 (uint64_t x);]]) function M.htole64(x) return lib.bin_htole64(x) end
ffi.fundef('bin_be64toh',[[uint64_t bin_be64toh (uint64_t x);]]) function M.be64toh(x) return lib.bin_be64toh(x) end
ffi.fundef('bin_le64toh',[[uint64_t bin_le64toh (uint64_t x);]]) function M.le64toh(x) return lib.bin_le64toh(x) end
--endian

M.jit_major = jit.version:match("LuaJIT (%d%.%d)")

if not rawget(_G, 'dostring') then
	if not rawget(_G, 'loadstring') then
		rawset(_G, 'loadstring', load)
	end
	local loadstring = rawget(_G, 'loadstring')
	rawset(_G, 'dostring', function(str) return assert(loadstring(str))() end)
end

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