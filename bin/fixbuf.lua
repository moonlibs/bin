---
-- This module provides buffer with constant capacity.
-- Module implements every method from @{bin.basebuf}
--
-- Example of usage [moonlibs/connection-scribe](https://github.com/moonlibs/connection-scribe/blob/7f7177fcd34dd016e83962dea08327a042be8849/connection/scribe.lua#L362)
-- @module bin.fixbuf

---
-- Implements write buffer.
-- Has following structure inside
--
--	struct bin_buf_#capasity {
--		  char   buf[#capasity];
--		  size_t cur;
--	};
--
-- @type fixbuf
local buf = {}

local ffi = require 'ffi.reloadable'
local C = ffi.C
local basebuf = require 'bin.basebuf'


function buf:alloc( sz )
	-- print("alloc for buf ",self, sz, ffi.sizeof(self[0]))
	if ffi.sizeof(self[0]) - self.cur < sz then
		error("No more space in fixed buffer",2)
	end
	self.cur = self.cur + sz
	return ffi.cast('char *',self) + self.cur - sz
end

---
-- Returns raw pointer *Doesn't grant ownership*.
--
-- **You can't continue to use pointer after buffer modification or after free of original object**
--
-- Mind GC!
-- @return `char *` ptr
-- @return `size` of written data
function buf:pv()
	return ffi.cast('char *',self),self.cur
end

---
-- Returns raw pointer, size and free of the buffer and destroys buffer.
--
-- Grants ownership of struct to the returned value (including gc)
-- use object after export is **prohibited**
-- @return `char *` start of the buffer
-- @return `size` of the buffer
-- @return `free` of the buffer
function buf:export()
	--[[
		local newptr = ffi.cast('char *',ffi.gc(self,nil))
		local sz = ffi.sizeof(self[0]) - ffi.sizeof(self.cur)
		return ffi.gc(newptr, C.free), self.cur, sz
	]]
	return ffi.gc(ffi.cast('char *',ffi.gc(self,nil)),C.free),
		self.cur,
		ffi.sizeof(self[0]) - ffi.sizeof(self.cur)
end

local function bin_buf_str( self )
	return string.format(
		'binbuf<0x%x>[%s/%s]',
		tonumber(ffi.cast('int',ffi.cast('char *',self))),
		tonumber(self.cur),tonumber(ffi.sizeof(self[0]) - ffi.sizeof(self.cur)))
end

for k,v in pairs(basebuf) do buf[k] = v end

local sizes = {}
-- 4k to 1Mb
for i = 12,20 do
	local sz = 2^i
	local cap = sz - ffi.sizeof('size_t')
	ffi.typedef('bin_buf_'..cap,
		'typedef struct bin_buf_'..cap..' { char buf['..cap..']; size_t cur; } bin_buf_'..cap..';'
		,{
			__index = buf;
			__tostring = bin_buf_str;
		}
	)
	table.insert(sizes,cap)
end

local M = {}

---
-- Creates buffer from range 4K - 1M.
-- @constructor
-- @param sz requested size
-- @return `fixbuf`
-- @raise if `sz` is bigger than 1M
function M.new(sz)
	sz = sz or 4088;
	for _,cap in ipairs(sizes) do
		if cap >= sz then
			-- print("choose ",cap, " for ",sz)
			local typename = 'bin_buf_'..cap
			-- local b = ffi.new( 'bin_buf_'..cap );
			local b =
				ffi.gc(
					ffi.cast( typename..'*', C.calloc( 1, ffi.sizeof(typename) ) ),
					C.free
				)
				b.cur = 0;
			return b
		end
	end
	error("Too big size requested "..tostring(sz))
end

return M