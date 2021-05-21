---
-- Implements Safe binary Reader.
--
-- Example of usage [ochaton/migrate](https://github.com/ochaton/migrate/blob/29663cf96b0103963a1f78dbbbc91df9bf1fec98/migrate/init.lua#L31)
--
-- Same as @{bin.rbuf} but safer.
-- Always checks bounds of the buffer.
-- @see bin.rbuf.dump
-- @see bin.rbuf.hex
-- @see bin.rbuf.move
-- @see bin.rbuf.avail
-- @module bin.saferbuf

---
-- Safe rbuf implements everything `bin.rbuf` does but adds bounds checks.
-- Has following structure.
--
--	struct bin_safe_rbuf {
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
-- @see bin.rbuf.dump
-- @see bin.rbuf.hex
-- @see bin.rbuf.move
-- @see bin.rbuf.avail
-- @type saferbuf
local srbuf = {}
local ffi = require 'ffi.reloadable'
local C = ffi.C

local base = require 'bin.base'
local rbuf = require 'bin.rbuf'.buf

srbuf.dump  = rbuf.dump
srbuf.hex   = rbuf.hex
srbuf.move  = rbuf.move
srbuf.avail = rbuf.avail

local function bin_safe_rbuf_str(self)
	return string.format(
		'binsrbuf<0x%x>[%s/%s]',
		tonumber(ffi.cast('int',ffi.cast('char *',self))),
		tonumber(self.p.c - self.buf),
		tonumber(self.len)
	)
end

local saferbuf_t = ffi.typedef('bin_safe_rbuf',[[
	typedef struct bin_safe_rbuf {
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
	} bin_safe_rbuf;
]],{
	__index = srbuf;
	__tostring = bin_safe_rbuf_str;
})

for _,ix in pairs({'i','u'}) do
	for _,t in pairs({
		'8',
		'16',
		'32',
		'64',
	}) do
		local sz = math.floor(tonumber(t)/8)
		local typename = ix..t

		srbuf[ typename ] = function(self)
			self:have(sz, 3)
			local n = self.p[typename][0]
			self.p[typename] = self.p[typename]+1
			return n
		end
		if sz > 1 then
			local htobe = 'bin_htobe' .. t
			local htole = 'bin_htole' .. t
			srbuf[ typename..'le' ] = function(self)
				self:have(sz, 3)
				local n = self.p[typename][0]
				self.p[typename] = self.p[typename]+1
				return C[htole]( n )
			end
			srbuf[ typename..'be' ] = function(self)
				self:have(sz, 3)
				local n = self.p[typename][0]
				self.p[typename] = self.p[typename]+1
				return C[htobe]( n )
			end
		end
	end
end

-- TODO: float, double

srbuf.V = srbuf.i32le;
srbuf.N = srbuf.i32be;

function srbuf:reb()
	local n = ffi.new("uint64_t [1]", 0)
	local shift = C.reb_decode(self.p.u8, self:avail(), ffi.cast('uint64_t *', n))
	if shift == 0 then
		error("Decoding REB failed", 2)
	else
		self:have(shift, 3)
		self.p.u8 = self.p.u8 + shift
		return n[0]
	end
end


---
-- Decodes VLQ number Opposite to @{bin.basebuf.ber} (LuaJIT >= 2.1).
-- @function srbuf:ber
-- @return `number` decoded value
if base.jit_major >= 20100 then
	function srbuf:ber()
		local n = 0ULL
		for i = 0,8 do
			n = bit.bor( bit.lshift(n,7), bit.band( 0x7f, self.p.u8[i] ) )
			self:have(i+1, 3)
			if self.p.u8[i] < 0x80 then
				self.p.u8 = self.p.u8 + i + 1
				return n
			end
		end
		error("Bad BER sequence",2)
	end
end

---
-- Reads `len` bytes from buffer and returns `string`.
-- @number len
-- @return string
function srbuf:str(len)
	self:have(len, 3)
	local str = ffi.string(self.p.c, len)
	self.p.c = self.p.c + len
	return str
end

---
-- Forwards cursor for `len` bytes (bounds checks inside)
-- @number len number of bytes
function srbuf:skip(len)
	self:have(len, 3)
	self.p.c = self.p.c + len
end

---
-- Checks that buffer has at least `bytes` till the end
-- @number[opt=0] bytes
-- @number[opt=2] lvl
-- @treturn number bytes to the end of the buffer
function srbuf:have(bytes, lvl)
	local avail = self:avail()
	bytes = bytes or 0
	if bytes > self:avail() then
		lvl = lvl or 2
		error("not enough bytes", lvl)
	end
	return avail
end

local M = {}
---
-- Creates reader from given pointer
-- @constructor
-- @tparam `char *` ptr string or pointer
-- @number[opt=#str] size of the buffer
-- @return `saferbuf`
function M.new(p, l)
	if not l then l = #p end
	local self = saferbuf_t{ buf = p; len = l; }
	self.p.c = p
	return self
end

return M