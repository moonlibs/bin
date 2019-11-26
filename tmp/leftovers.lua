local bin = require 'bin'
-- local buf = bin

	function buf:ber(n)
		n = ffi.cast('uint32_t',n)
		-- n = ffi.cast('uint64_t',n)
		if n < 0x80 then
			local p = ffi.cast(uint8_t,self:alloc(1))
			p[0] = n
		elseif n < 0x4000 then
			local p = ffi.cast(uint8_t,self:alloc(2))
			-- print("2>",bit.rshift(n,7))
			ffi.cast(uint8_t, p)[0] = bit.bor(0x80, bit.rshift(n,7))
			ffi.cast(uint8_t, p)[1] = bit.band(n,0x7f)
		elseif n < 0x200000 then
			local p = ffi.cast(uint8_t,self:alloc(3))
			ffi.cast(uint8_t, p)[0] = bit.bor(0x80, bit.rshift(n,14))
			ffi.cast(uint8_t, p)[1] = bit.bor(0x80, bit.rshift(n,7))
			ffi.cast(uint8_t, p)[2] = bit.band(n,0x7f)
		elseif n < 0x10000000 then
			local p = ffi.cast(uint8_t,self:alloc(4))
			ffi.cast(uint8_t, p)[0] = bit.bor(0x80, bit.rshift(n,21))
			ffi.cast(uint8_t, p)[1] = bit.bor(0x80, bit.rshift(n,14))
			ffi.cast(uint8_t, p)[2] = bit.bor(0x80, bit.rshift(n,7))
			ffi.cast(uint8_t, p)[3] = bit.band(n,0x7f)
		else
			local p = ffi.cast(uint8_t,self:alloc(5))
			ffi.cast(uint8_t, p)[0] = bit.bor(0x80, bit.rshift(n,28))
			ffi.cast(uint8_t, p)[1] = bit.bor(0x80, bit.rshift(n,21))
			ffi.cast(uint8_t, p)[2] = bit.bor(0x80, bit.rshift(n,14))
			ffi.cast(uint8_t, p)[3] = bit.bor(0x80, bit.rshift(n,7))
			ffi.cast(uint8_t, p)[4] = bit.band(n,0x7f)
		end
	end


	function buf:ber2(x)
		x = ffi.cast('uint64_t',x)
		local p
		if x < 0x80 then
			p = self:alloc(1)
			ffi.cast(uint8_t, p)[0] = x
		else
			local len =
				-- x < 0x80ULL               and 1 or
				x < 0x4000ULL             and 2 or
				x < 0x200000ULL           and 3 or
				x < 0x10000000ULL         and 4 or
				x < 0x800000000ULL        and 5 or
				x < 0x40000000000ULL      and 6 or
				x < 0x2000000000000ULL    and 7 or
				x < 0x100000000000000ULL  and 8 or 9
				-- x < 0x8000000000000000 and 9 or
			
			p = ffi.cast(uint8_t,self:alloc(len))
			for i = 0,len-2 do
				p[i] = bit.bor(0x80, bit.rshift(x, 7*(len-i-1) ))
			end
			p[len-1] = bit.band(x,0x7f)
		end
	end


local clock = require 'clock'

local N = 1e7

-- local st = clock.proc()
-- local buf = bin.buf(64)
-- for i = 1,N do
-- 	buf.cur = 0
-- 	buf:ber3(0x12345678LL)
-- end
-- local r = clock.proc() - st
-- print(string.format("%d/%0.6fs = %0.4fs", N,r, N/r))

local st = clock.proc()
local buf = bin.buf(64)
for i = 1,N do
	buf.cur = 0
	buf:ber(0x12345678LL)
end
local r = clock.proc() - st
print(string.format("%d/%0.6fs = %0.4fs", N,r, N/r))

local st = clock.proc()
local buf = bin.buf(64)
for i = 1,N do
	buf.cur = 0
	buf:ber2(0x12345678LL)
end
local r = clock.proc() - st
print(string.format("%d/%0.6fs = %0.4fs", N,r, N/r))





	function buf:reb(x)
		x = ffi.cast('uint64_t',x)
		if x < 0x80 then
			p = self:alloc(1)
			ffi.cast(uint8_t, p)[0] = x
		else
			local p
			while x > 0 do
				p = self:alloc(1)
				if x > 0x7f then
					ffi.cast(uint8_t, p)[0] = bit.bor(bit.band(x,0x7f),0x80)
				else
					ffi.cast(uint8_t, p)[0] = bit.band(x,0x7f)
				end
				x = bit.rshift(x,7)
			end
		end
	end

-- if true then -- bench
-- jit.off()
local clock = require 'clock'

local N = 1e7

local st = clock.proc()
local buf = bin.buf(64)
for i = 1,N do
	buf.cur = 0
	buf:reb(0x12345678LL)
end
local r = clock.proc() - st
print(string.format("%d/%0.6fs = %0.4fs", N,r, N/r))

local st = clock.proc()
local buf = bin.buf(64)
for i = 1,N do
	buf.cur = 0
	buf:reb2(0x12345678LL)
end
local r = clock.proc() - st
print(string.format("%d/%0.6fs = %0.4fs", N,r, N/r))


do return end