---
-- Implements unsafe binary Reader.
--
-- Same as `bin.basebuf` supports decoding numbers
-- into any endianess.
--
-- `{u,i}{8,16,32,64}{be,le,}` are supported opposite to defined at @{bin.basebuf}.
-- @module bin.rbuf

---
-- Implements unsafe binary Reader.
-- Has following structure.
--
--	struct bin_rbuf {
--	 	const char * buf;
--	 	union {
--	 		const char     *c;
--	 		const int8_t   *i8;
--	 		const uint8_t  *u8;
--	 		const int16_t  *i16;
--	 		const uint16_t *u16;
--	 		const int32_t  *i32;
--	 		const uint32_t *u32;
--	 		const int64_t  *i64;
--	 		const uint64_t *u64;
--	 	} p;
--	 	size_t len;
--	};
-- @type rbuf
local rbuf = {}
local ffi = require 'ffi.reloadable'
local C = ffi.C

local base = require 'bin.base'

local function bin_rbuf_str( self )
	return string.format(
		'binrbuf<0x%x>[%s/%s]',
		tonumber(ffi.cast('int',ffi.cast('char *',self))),
		tonumber(self.p.c - self.buf),
		tonumber(self.len)
	)
end

local rbuf_t = ffi.typedef('bin_rbuf',[[
	typedef struct bin_rbuf {
		const char * buf;
		union {
			const char     *c;
			const int8_t   *i8;
			const uint8_t  *u8;
			const int16_t  *i16;
			const uint16_t *u16;
			const int32_t  *i32;
			const uint32_t *u32;
			const int64_t  *i64;
			const uint64_t *u64;
		} p;

		size_t len;
	} bin_rbuf;
]],{
	__index = rbuf;
	__tostring = bin_rbuf_str;
})

for _,ix in pairs({'i','u'}) do
	for _,t in pairs({'8', '16', '32', '64'}) do
		local sz = math.floor(tonumber(t)/8)
		local typename = ix..t

		rbuf[ typename ] = function(self)
			local n = self.p[typename][0]
			self.p[typename] = self.p[typename]+1
			return n
		end
		if sz > 1 then
			local htobe = 'bin_htobe' .. t
			local htole = 'bin_htole' .. t
			rbuf[ typename..'le' ] = function(self)
				local n = self.p[typename][0]
				self.p[typename] = self.p[typename]+1
				return C[htole]( n )
			end
			rbuf[ typename..'be' ] = function(self)
				local n = self.p[typename][0]
				self.p[typename] = self.p[typename]+1
				return C[htobe]( n )
			end
		end
	end
end

-- TODO: float, double

rbuf.V = rbuf.i32le;
rbuf.N = rbuf.i32be;

function rbuf:reb()
	local n = ffi.new("uint64_t [1]", 0)
	local shift = C.reb_decode(self.p.u8, self:avail(), ffi.cast('uint64_t *', n))
	if shift == 0 then
		error("Decoding REB failed", 2)
	else
		self.p.u8 = self.p.u8 + shift
		return n[0]
	end
end

---
-- Decodes VLQ number Opposite to @{bin.basebuf.ber} (LuaJIT >= 2.1).
-- @function rbuf:ber
-- @return `number` decoded value
if base.jit_major >= 20100 then
	function rbuf:ber()
		local n = 0ULL
		for i = 0,8 do
			n = bit.bor( bit.lshift(n,7), bit.band( 0x7f, self.p.u8[i] ) )
			if self.p.u8[i] < 0x80 then
				self.p.u8 = self.p.u8 + i + 1
				return n
			end
		end
		error("Bad BER sequence",2)
	end
end

---
-- [unsafe] Extracts `len` bytes from buffer as `string`
-- @number len size of resulting string
-- @return `string` str
function rbuf:str(len)
	local str = ffi.string( self.p.c, len )
	self.p.c = self.p.c + len
	return str
end

---
-- [safe] Returns nice hexdump of the remaining buffer
-- @see bin.base.xd
-- @return `string` hexdump
function rbuf:dump()
	return base.xd(self.p.c,self.len - (self.p.c-self.buf),nil)
end

---
-- [safe] Returns hex representation of the remaining buffer
-- @see bin.base.hex
-- @return `string` hex
function rbuf:hex()
	return base.hex(self.p.c,self.len - (self.p.c-self.buf))
end

---
-- [safe] memmoves remaining buffer to the beginning.
-- shrinks `len` of the buffer.
function rbuf:move()
	local size = self.len - (self.p.c - self.buf)
	C.memmove(self.buf, self.p.c, size)
	self.p.c = self.buf
	self.len = size
end

---
-- [unsafe] Forwards cursor for `len` bytes (accepts negatives).
-- @number `len`
function rbuf:skip(len)
	self.p.c = self.p.c + len
end

---
-- [safe] Returns remaining part of the buffer
-- @return `left` bytes
function rbuf:avail()
	return self.len - (self.p.c-self.buf)
end

local M = { buf = rbuf }

---
-- Creates rbuf from pointer
-- @constructor
-- @tparam char* p pointer or string
-- @param[opt=#p] l length of the pointer
-- @return `rbuf`
function M.new(p, l)
	if not l then l = #p end
	local self = rbuf_t{ buf = p; len = l; }
	self.p.c = p
	return self
end

return M