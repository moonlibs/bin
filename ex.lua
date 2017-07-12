local bin = require 'bin'
local ffi = require 'ffi'

--[[ For the first: nice hexdump ]]--

-- print hexdump of lua string
print(bin.xd("some binary string"))

--[[ Gives the following output:
[0000]   73 6F 6D 65  20 62 69 6E  61 72 79 20  73 74 72 69   some  bin ary  stri
[0010]   6E 67                                                ng
]]

-- Accepts arbitrary pointer and could take length
print(bin.xd(ffi.cast("void *","string"),4))
--[[ Gives the following output:
[0000]   73 74 72 69                                          stri
]]

-- For compact output there is `hex`
print(bin.hex("some binary string"))
-- 736F6D652062696E61727920737472696E67

--[[ There is also endian conversion functions ]]--

print(bin.htobe16(0x1234)) -- 13330
print(bin.htole16(0x1234)) -- 4660
print(bin.be16toh(0x1234)) -- 13330
print(bin.le16toh(0x1234)) -- 4660
print(bin.htobe32(0x1234)) -- 873594880
print(bin.htole32(0x1234)) -- 4660
print(bin.be32toh(0x1234)) -- 873594880
print(bin.le32toh(0x1234)) -- 4660
print(bin.htobe64(0x1234)) -- 3752061439553044480ULL
print(bin.htole64(0x1234)) -- 4660ULL
print(bin.be64toh(0x1234)) -- 3752061439553044480ULL
print(bin.le64toh(0x1234)) -- 4660ULL

--[[ And buffer objects. Write buffer ]]--

local desired_size = 4096
local buf = bin.buf(desired_size)
print(buf)
-- binbuf<0x31004200>[0/4096]
--         address  used/total

-- accepts encoding of integers:

buf:uint8(0xff)
print(buf:hex()) -- FF
buf:uint32(0x12345678)
print(buf:hex()) -- FF78563412
buf:uint32(0x12345678)

-- Also support endianness

buf:uint32be(0x12345678) -- be for big endian
print(buf:hex()) -- FF785634127856341212345678

buf:uint32le(0x12345678) -- le for little endian
print(buf:hex()) -- FF78563412785634121234567878563412

--[[
Complete list of numeric methods:
uint8     int8     uint8be     int8le
uint16    int16    uint16be    int16le
uint32    int32    uint32be    int32le
uint64    int64    uint64be    int64le
V = int32le
N = int32be
ber - for BER packed integer (perl pack w)
reb - for reverse BER (big endian)
f   float    floatbe   floatle
d   double   doublebe  doublele <- this one looks so weird ;)
]]

-- buffer may be cleared (reset pos to zero or other pos within buf)
buf:clear(8)
print(buf:hex()) -- FF78563412785634
print(buf) -- binbuf<0x31004200>[8/4096]
buf:clear()
print(buf) -- binbuf<0x31004200>[0/4096]

buf:double(0.123456)
print(buf:hex()) -- FF78563412785634
buf:doublebe(0.123456)
print(buf:hex()) -- BFB67EFACF9ABF3F3FBF9ACFFA7EB6BF

buf:clear()

buf:float(0.123456)
print(buf:hex()) -- 80D6FC3D
buf:floatbe(0.123456)
print(buf:hex()) -- 80D6FC3D3DFCD680

buf:clear()

--[[ Also there is simple :char ]]
buf:char('x') -- !only one char
buf:char(0xfe) -- but also accepts number as byte

print(buf:hex()) -- 78FE

--[[ for strings or buffers there is copy ]]

buf:copy("putme")
buf:copy("notlong",3)

print(buf:dump())
-- [0000]   78 FE 70 75  74 6D 65 6E  6F 74                      x.pu tmen ot

buf:clear()

--[[ For manual operation there is :alloc ]]
local nbytes = 5
local p = buf:alloc(nbytes)
ffi.copy(p,"12345",5)
print(buf)
print(buf:dump())
-- binbuf<0x3a801400>[5/4096]
-- [0000]   31 32 33 34  35                                      1234 5

--[[ If you need raw char data fro buffer, call :pv() ]]

local ptr,len = buf:pv()
local str = ffi.string(ptr,len)

---
--- Inside object real buffer is allocated internally and will be freed with buf destroy
--- If you need to use buffer (for ex for iovec), you must keep reference to buf
--- But since buf is not a pointer to the beginning of char data there is an :export method.
--- It allows to take out character data itself with correct gc-guarded poiner
---

local pv
do
	local buf = bin.buf(4096)
	buf:copy("test")
	local len
	pv,len = buf:export()
	-- now buffer can't be used anymore for writing data
end
collectgarbage()
-- but pv still points to original data and memory will be freed only when pv will be freed
pv = nil
collectgarbage()
-- now memory was freed. no one should use data under buf or pv

