---
-- This module implements common write buffer operations.
--
-- basebuf supports `{u,}int{8,16,32,64}{be,le,}` methods.
--
-- All of them accepts single argument n and pushes it with corresponding casting
-- @classmod bin.basebuf
local buf = {}

local base = require 'bin.base'
local rbuf = require 'bin.rbuf'

local ffi = require 'ffi.reloadable'
local C = ffi.C

ffi.typedef('double_union',[[
	typedef union double_union {
		double   d;
		uint64_t u;
	} double_union;
]]);
ffi.typedef('float_union',[[
	typedef union float_union {
		float   d;
		uint32_t u;
	} float_union;
]]);

for _,ix in pairs({'','u'}) do
	for _,ti in pairs({'8', '16', '32', '64'}) do
		local t = ti
		local sz = math.floor(tonumber(ti)/8)
		local t_t = ffi.typeof(ix..'int'..t..'_t *')
		buf[ ix..'int'..t ] = function(self,n)
			local p = self:alloc(sz)
			ffi.cast(t_t, p)[0] = n
		end
		if sz > 1 then
			local htobe = 'bin_htobe' .. t
			local htole = 'bin_htole' .. t
			buf[ ix..'int'..t..'le' ] = function(self,n)
				local p = self:alloc(sz)
				ffi.cast(t_t, p)[0] = C[htole](n)
			end
			buf[ ix..'int'..t..'be' ] = function(self,n)
				local p = self:alloc(sz)
				ffi.cast(t_t, p)[0] = C[htobe](n)
			end
		end
	end
end

buf.V = buf.int32le;
buf.N = buf.int32be;

local double_t  = ffi.typeof('double *')
local float_t   = ffi.typeof('float *')
local uint8_t   = ffi.typeof('uint8_t *')

---
-- Pushes `n` as double (8 bytes) into buffer
-- @param n number
function buf:double(n)
	local p = self:alloc(8)
	ffi.cast(double_t, p)[0] = n
end
---
-- Pushes `n` as double (8 bytes) casting to LE into buffer
-- @param n number
function buf:doublele(n)
	local p = ffi.cast('double_union *', self:alloc(8))
	p[0].d = n
	p[0].u = C.bin_htole64(p[0].u)
end
---
-- Pushes `n` as double (8 bytes) casting to BE into buffer
-- @param n number
function buf:doublebe(n)
	local p = ffi.cast('double_union *', self:alloc(8))
	p[0].d = n
	p[0].u = C.bin_htobe64(p[0].u)
end
buf.d = buf.double;

---
-- Pushes `n` as float (4 bytes) into buffer
-- @number n
function buf:float(n)
	local p = self:alloc(4)
	ffi.cast(float_t, p)[0] = n
end
---
-- Pushes `n` as float (4 bytes) casting to LE into buffer
-- @number n
function buf:floatle(n)
	local p = ffi.cast('float_union *', self:alloc(4))
	p[0].d = n
	p[0].u = C.bin_htole32(p[0].u)
end
---
-- Pushes `n` as float (4 bytes) casting to BE into buffer
-- @number n
function buf:floatbe(n)
	local p = ffi.cast('float_union *', self:alloc(4))
	p[0].d = n
	p[0].u = C.bin_htobe32(p[0].u)
end
buf.f = buf.float;

-- compatitbility with lower version of LuaJIT
local lims = {
	2ULL^7 , 2ULL^14, 2ULL^21,
	2ULL^28, 2ULL^35, 2ULL^42,
	2ULL^49, 2ULL^56, 2ULL^63,
}
function buf.reb (self, n)
	local size = 1
	while size <= #lims and n >= lims[size] do
		size = size + 1
	end

	local p = ffi.cast(uint8_t, self:alloc(size))
	if C.reb_encode(n, p, self.len) == 1 then
		error("REB encoding failed for " .. n)
	end
end

---
-- Pushes number performing variable length encoding
--
--	[wikipedia](https://en.wikipedia.org/wiki/Variable-length_quantity#General_structure)
-- @function buf:ber
-- @param n number
if base.jit_major >= 20100 then
	local func = [[
		local ffi = require 'ffi'
		local uint8_t  = ffi.typeof('uint8_t *')
		return function(self,n)
	]]
	for i = 1,9 do
		local lim = bit.lshift(1ULL,7*i)
		if i == 1 then
			func = func .. "if n < "..string.format("0x%xULL",tonumber(lim)).." then\n"
		elseif i == 9 then
			func = func .. "else --- < "..string.format("0x%xULL",tonumber(lim)).."\n"
		else
			func = func .. "elseif n < "..string.format("0x%xULL",tonumber(lim)).." then\n"
		end
		func = func .. "\tlocal p = ffi.cast(uint8_t,self:alloc("..i.."))\n"
		if i > 1 then
			for ptr = 0,i-2 do
				func = func .. "\tp["..ptr.."] = bit.bor(0x80, bit.rshift(n,"..( 7*(i-ptr-1) ).."))\n"
			end
		end
		func = func .. "\tp["..(i-1).."] = bit.band(0x7f, n)\n"
	end
	func = func .. "end\nend\n"
	buf.ber = _G.dostring(func)
end

---
-- Pushes first byte of the string
-- @string x
function buf:char(x)
	local p = self:alloc(1)
	if type(x) == 'string' then
		-- assert(#x == 1, "String should be 1 byte length")
		ffi.cast(uint8_t, p)[0] = x:byte(1)
	else
		ffi.cast(uint8_t, p)[0] = tonumber(x)
	end
end

---
-- Control methods
-- @section controls

---
-- Copies data from given string or pointer
-- @param src string or pointer
-- @param[opt=#src] len bytes of src to copy
function buf:copy(data,len)
	if not len then len = #data end

	local p = self:alloc(len)
	ffi.copy(p,ffi.cast('char *',data),len)
end

---
-- Rollbacks cursor to given position
-- @number[opt=0] n
function buf:clear(n)
	n = n or 0
	assert(n <= self.cur, "position must be less than current length")
	self.cur = n
end

---
-- Returns hexdump of the buffer
-- @see bin.base.xd
-- @treturn string hexdump
function buf:dump()
	local p,len = self:pv()
	return base.xd(p,len,nil)
end
buf.xd = buf.dump

---
-- Returns hex representation (analog of string.tohex)
-- @see bin.base.hex
-- @treturn string hex
function buf:hex()
	local p,len = self:pv()
	return base.hex(p,len)
end

---
-- Creates new unsafe `bin.rbuf` from the buffer
-- @treturn @{bin.rbuf} rbuf
function buf:reader()
	local p,l = self:pv()
	return rbuf.new(p, l)
end

return buf