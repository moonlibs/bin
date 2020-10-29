local M = {}

local ffi = require 'ffi.reloadable'
local C = ffi.C

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
	local buf = C.bin_hex(ffi.cast("char*",data),len);
	local rv
	if buf then
		rv = ffi.string(buf)
		C.free(buf)
	else
		error("Failed")
	end
	return rv
end

function M.xd(data, len)
	len = len or #data
	local buf = C.bin_xd(ffi.cast("char*",data),len,nil);
	local rv
	if buf then
		rv = ffi.string(buf)
		C.free(buf)
	else
		error("Failed")
	end
	return rv
end

return M