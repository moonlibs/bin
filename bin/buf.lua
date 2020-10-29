local ffi = require 'ffi.reloadable'
local C = ffi.C

local basebuf = require 'bin.basebuf'

local function capacity(sz)
	-- grow by 64b blocks or by 1/4 of data aligned by 64b
	sz = tonumber(sz)
	local alg = math.ceil(sz / 4 / 64) * 64
	return math.ceil(sz / alg) * alg
end

local buf = {}
function buf:alloc( sz )
	if self.len - self.cur < sz then
		self.len = capacity(self.cur + sz);
		self.buf = C.realloc(self.buf,self.len)
	end
	if self.buf == nil then
		error("Access to exported buffer",2)
	end
	self.cur = self.cur + sz
	return self.buf + self.cur - sz
end

function buf:pv()
	return self.buf,self.cur
end

function buf:export()
	local p,len = self:pv()
	self.buf = nil
	return ffi.gc(p, C.free), len, self.len
end

local function bin_buf_str( self )
	return string.format(
		'binbuf<0x%x>[%s/%s]',
		tonumber(ffi.cast('int',self.buf)),
		tonumber(self.cur),tonumber(self.len))
end
local function bin_buf_free(self)
	-- print("freeing buf ", self.buf)
	if self.buf ~= nil then
		C.free(self.buf)
	end
end

for k,v in pairs(basebuf) do buf[k] = v end

ffi.typedef('bin_buf',[[
	typedef struct bin_buf {
		char  *buf;
		size_t cur;
		size_t len;
	} bin_buf;
]], {
	__gc = bin_buf_free;
	__index = buf;
	__tostring = bin_buf_str;

})

local M = {}
function M.new(sz)
	sz = sz or 4096;
	-- sz = sz or 16;
	local b = ffi.new( 'bin_buf');
	b.len = capacity(sz);
	-- b.buf = ffi.new('char[?]',b.len) -- memory corruption after free ((
	b.buf = C.calloc(b.len,1) -- memory corruption after free ((
	return b
end

return M