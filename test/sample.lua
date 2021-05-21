local ffi = require 'ffi'

-- box.cfg {
-- 	background = false;
-- 	logger_nonblock = true;
-- 	read_only = true;
-- 	wal_mode = 'none';
-- }

local fiber = require 'fiber'

local function dump(x)
	local j = require'json'.new()
	j.cfg{
		encode_use_tostring = true;
	}
	return j.encode(x)
end

package.path = "./?.lua;"..package.path
print(package.searchpath('bin', package.path))

local bin = require 'bin'

if false then -- bench
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
end -- bench

do
	local buf = bin.buf(64)
	-- buf:copy("abcdef1234567890");
	-- buf:ber(0x12345678LL)
	-- buf:ber2(0x12345678LL)
	buf:reb(0x1234567890LL)
	-- buf:char(0xff)
	-- buf:char(0xff)
	buf:ber(0x1234567890LL)
	print("encoded = ",0x1234567890LL)

	print(buf)
	print(buf:dump())
	local rbuf= buf:reader()
	print(rbuf)
	print("decoded reb = ",rbuf:reb())
	-- rbuf.p.u16 = rbuf.p.u16+1
	print("decoded ber = ",rbuf:ber())
	-- print(rbuf:u32())
	-- print(rbuf:N())
	print(rbuf)
end

do return end

do
	local p,l
	do
		local buf = bin.buf(64)
		print(buf)
		for i = 0,127 do buf:char('A') end
		print(buf:dump())
		fiber.sleep(0.1)
		collectgarbage()
		print(buf:dump())
		p,l = buf:export()
	end
	collectgarbage()
	print(bin.xd(p,l))
end

print(bin.xd("test"));

print(string.format("%04x",bin.htole16(0x1234)))
print(string.format("%04x",bin.htobe16(0x1234)))
print(string.format("%08x",bin.htole32(0x12345678)))
print(string.format("%08x",bin.htobe32(0x12345678)))

print(bin.hex("some 1234"))


-- local buf = bin.fixbuf()
local buf = bin.buf()

print(buf)
print(bin.xd(buf.buf,16))
local p = buf:alloc(8)
ffi.copy(p,"12345678")
print(bin.xd(buf.buf,16))
print(buf)

buf:uint8(0xff)
buf:int8(-300)
buf:int8(0)
buf:uint64be(0x1234567890ABCDEFULL)

buf:V(0x12345678ULL)

buf:int8(0xfe)

buf:ber(0x12345678)

print(buf)
print(bin.xd(buf.buf,32))

print(buf:dump())

print(buf:hex())


print("new buf")
local buf = bin.fixbuf()
local p = buf:alloc(8)
ffi.copy(p,"12345678")
buf:ber(0x12345678)
buf:V(0x12345678ULL)
print(buf:dump())
print(buf:hex())



-- print(string.format("%016s",tostring(bin.htole64(0x1234567890ABCDEFULL))))
-- print(string.format("%016x",bin.htobe64(0x12345678)))

-- local cn = scr("localhost",1463,{})