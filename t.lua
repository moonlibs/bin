--[[
You can run this tests using typing this in the shell:
# LuaJIT (tested on 2.0.5)
LUA_CPATH="./?.so" LUA_PATH="./?.lua;/home/ochaton/.luarocks/share/lua/5.1/?.lua" luajit t.lua
	# Tarantool (tested on 1.10.2-26-gb2ddd18)
LUA_CPATH="./?.so" LUA_PATH="./?.lua;/home/ochaton/.luarocks/share/lua/5.1/?.lua" tarantool t.lua
]]

local bin = require 'bin'

-- test cases was taken from https://rosettacode.org/wiki/Variable-length_quantity#C
local numbers = { 0x7f, 0x4000, 0, 0x3ffffe, 0x1fffff, 0x200000, 0x3311a1234df31413ULL }
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
