--[[
You can run this tests using typing this in the shell:
# LuaJIT (tested on 2.0.5)
luajit test/t.lua

# Tarantool (tested on 1.10.2-26-gb2ddd18)
tarantool test/t.lua
]]

package.path = "./?.lua;"..package.path
print(package.searchpath('bin', package.path))
-- TODO: import tap based tests
local bin = require 'bin'

-- test cases was taken from https://rosettacode.org/wiki/Variable-length_quantity#C
local numbers = {
	0x7f, 0x4000, 0, 0x3ffffe, 0x1fffff, 0, 0x200000, 0x3311a1234df31413ULL,
	-1ULL, 18446744062075611165ULL
}

local buf = bin.buf()
for _, num in ipairs(numbers) do
	buf:reb(num)
end

local rbuf = buf:reader()
for _, num in ipairs(numbers) do
	local got = rbuf:reb()
	assert(got == num, ("Expected %s got %s"):format(num, got))
	print("ok - ", num)
end

-- memory leak tests:
local buf = bin.rbuf("") -- empty buffer :)
local ok = pcall(buf.reb, buf)
assert(not ok, "REB decoding should fail for empty buf")
print("ok - ", "failed REB decoding for empty buf")

-- corrupted REB:
local buf = bin.buf(1) -- 1 byte buffer
buf:char(0xff) -- transmit 0xff into it
local rbuf = buf:reader()

local ok = pcall(rbuf.reb, rbuf)
assert(not ok, "REB decoding should fail")
print("ok - ", "failed REB decoding for corrupted buf")

-- \xFF \xFF is invalid REB:
local buf = bin.buf(1)
buf:copy(("\xFF"):rep(2))

local rbuf = buf:reader()
local ok = pcall(rbuf.reb, rbuf)
assert(not ok, "REB decoding must fail for \xFF\xFF")
print("ok - ", "REB decode fails for \\xFF\\xFF")

assert(rbuf.len == 2, "rbuf.len is 2")
print("ok - ", "rbuf.len is 2")

assert(rbuf:avail() == 2, "rbuf:avail() is 2")
print("ok - ", "rbuf:avail() is 2 - no bytes were consumed after malformed REB")

local buf = bin.buf()
for i = 0, 64 do
	local left, center, right = 2ULL^i-1, 2ULL^i, 2ULL^i+1

	buf:reb(left)
	buf:reb(center)
	buf:reb(right)
end

local rbuf = buf:reader()
for i = 0, 64 do
	local center = 2ULL^i
	local left, right = center-1, center+1

	print("ok -", select(2, assert(rbuf:reb() == left,   ("reb_decode(reb_encode(%s)) == %s"):format(left, left))))
	print("ok -", select(2, assert(rbuf:reb() == center, ("reb_decode(reb_encode(%s)) == %s"):format(center, center))))
	print("ok -", select(2, assert(rbuf:reb() == right,  ("reb_decode(reb_encode(%s)) == %s"):format(right, right))))
end
