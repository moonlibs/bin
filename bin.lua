--[[

local bin = require 'bin'

print(bin.xd("some binary string"))

print(bin.htobe32( number ))

-- create a buffer of fixed size
-- (no grow allowed)
local buf = bin.fixbuf(65536);

-- create a buffer with flexible size
-- could be reallocated, but requires 2 x malloc per buffer

local buf = bin.buf(65536);


TODO: iovec?

]]


local M = { V = 3 }
local ffi = require 'ffi.reloadable'
local lib = ffi.load(package.searchpath('libluabin-scm-'..M.V, package.cpath), true)
local C = ffi.C

--- hexdump
ffi.typedef('xd_conf',[[
	typedef struct {
		uint8_t row;
		uint8_t hpad;
		uint8_t cpad;
		uint8_t hsp;
		uint8_t csp;
		uint8_t cols;
	} xd_conf;
]]);
ffi.fundef('bin_xd',[[
	char * bin_xd(const char *data, size_t size, xd_conf *cf);
]])
ffi.fundef('free',[[
	void free (void *);
]])
ffi.fundef('reb_decode',[[
	uint8_t reb_decode(const char *p, size_t size, uint64_t * result);
]])
ffi.fundef('reb_encode',[[
	uint8_t reb_encode(uint64_t n, char *buf, size_t size);
]])
function M.xd( data, len )
	len = len or #data
	local buf = lib.bin_xd(ffi.cast("char*",data),len,nil);
	local rv
	if buf then
		rv = ffi.string(buf)
		ffi.C.free(buf)
	else
		error("Failed")
	end
	return rv
end
--- hexdump

-- endian
ffi.fundef('bin_htobe16',[[uint16_t bin_htobe16 (uint16_t x);]]) function M.htobe16(x) return lib.bin_htobe16(x) end
ffi.fundef('bin_htole16',[[uint16_t bin_htole16 (uint16_t x);]]) function M.htole16(x) return lib.bin_htole16(x) end
ffi.fundef('bin_be16toh',[[uint16_t bin_be16toh (uint16_t x);]]) function M.be16toh(x) return lib.bin_be16toh(x) end
ffi.fundef('bin_le16toh',[[uint16_t bin_le16toh (uint16_t x);]]) function M.le16toh(x) return lib.bin_le16toh(x) end
ffi.fundef('bin_htobe32',[[uint32_t bin_htobe32 (uint32_t x);]]) function M.htobe32(x) return lib.bin_htobe32(x) end
ffi.fundef('bin_htole32',[[uint32_t bin_htole32 (uint32_t x);]]) function M.htole32(x) return lib.bin_htole32(x) end
ffi.fundef('bin_be32toh',[[uint32_t bin_be32toh (uint32_t x);]]) function M.be32toh(x) return lib.bin_be32toh(x) end
ffi.fundef('bin_le32toh',[[uint32_t bin_le32toh (uint32_t x);]]) function M.le32toh(x) return lib.bin_le32toh(x) end
ffi.fundef('bin_htobe64',[[uint64_t bin_htobe64 (uint64_t x);]]) function M.htobe64(x) return lib.bin_htobe64(x) end
ffi.fundef('bin_htole64',[[uint64_t bin_htole64 (uint64_t x);]]) function M.htole64(x) return lib.bin_htole64(x) end
ffi.fundef('bin_be64toh',[[uint64_t bin_be64toh (uint64_t x);]]) function M.be64toh(x) return lib.bin_be64toh(x) end
ffi.fundef('bin_le64toh',[[uint64_t bin_le64toh (uint64_t x);]]) function M.le64toh(x) return lib.bin_le64toh(x) end
--endian

--hex
ffi.fundef('bin_hex',[[
	char * bin_hex(char *p, size_t size);
]])
ffi.fundef('free',[[
	void free (void *);
]])
function M.hex( data, len )
	len = len or #data
	local buf = lib.bin_hex(ffi.cast("char*",data),len);
	local rv
	if buf then
		rv = ffi.string(buf)
		ffi.C.free(buf)
	else
		error("Failed")
	end
	return rv
end
--hex

local buf = {}

ffi.fundef('calloc',  [[ void *calloc(size_t count, size_t size); ]])
ffi.fundef('malloc',  [[ void * malloc(size_t size); ]])
ffi.fundef('realloc', [[ void * realloc(void *ptr, size_t size); ]])
ffi.fundef('free',    [[ void free(void *ptr); ]])
ffi.fundef('memmove', [[ void * memmove(void *dst, const void *src, size_t len); ]])

local jit_major = jit.version:match("LuaJIT (%d%.%d)")

if not rawget(_G, 'dostring') then
	if not rawget(_G, 'loadstring') then
		rawset(_G, 'loadstring', load)
	end
	local loadstring = rawget(_G, 'loadstring')
	rawset(_G, 'dostring', function(str) return assert(loadstring(str))() end)
end

do -- base_buf
	local double_union = ffi.typedef('double_union',[[
		typedef union double_union {
			double   d;
			uint64_t u;
		} double_union;
	]]);
	local float_union = ffi.typedef('float_union',[[
		typedef union float_union {
			float   d;
			uint32_t u;
		} float_union;
	]]);
	for _,ix in pairs({'','u'}) do
		for _,ti in pairs({
			'8',
			'16',
			'32',
			'64',
		}) do
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
					ffi.cast(t_t, p)[0] = lib[htole](n)
				end
				buf[ ix..'int'..t..'be' ] = function(self,n)
					local p = self:alloc(sz)
					ffi.cast(t_t, p)[0] = lib[htobe](n)
				end
			end
		end
	end

	buf.V = buf.int32le;
	buf.N = buf.int32be;

	local double_t  = ffi.typeof('double *')
	local float_t   = ffi.typeof('float *')
	local uint8_t   = ffi.typeof('uint8_t *')
	local uint64_t  = ffi.typeof('uint64_t *')

	function buf:double(n)
		local p = self:alloc(8)
		ffi.cast(double_t, p)[0] = n
	end
	function buf:doublele(n)
		local p = ffi.cast('double_union *', self:alloc(8))
		p[0].d = n
		p[0].u = lib.bin_htole64(p[0].u)
	end
	function buf:doublebe(n)
		local p = ffi.cast('double_union *', self:alloc(8))
		p[0].d = n
		p[0].u = lib.bin_htobe64(p[0].u)
	end
	buf.d = buf.double;

	function buf:float(n)
		local p = self:alloc(4)
		ffi.cast(float_t, p)[0] = n
	end
	function buf:floatle(n)
		local p = ffi.cast('float_union *', self:alloc(4))
		p[0].d = n
		p[0].u = lib.bin_htole32(p[0].u)
	end
	function buf:floatbe(n)
		local p = ffi.cast('float_union *', self:alloc(4))
		p[0].d = n
		p[0].u = lib.bin_htobe32(p[0].u)
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

	if jit_major >= "2.1" then
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
		buf.ber = dostring(func)
	end

	function buf:char(x)
		local p = self:alloc(1)
		if type(x) == 'string' then
			-- assert(#x == 1, "String should be 1 byte length")
			ffi.cast(uint8_t, p)[0] = x:byte(1)
		else
			ffi.cast(uint8_t, p)[0] = tonumber(x)
		end
	end

	function buf:copy(data,len)
		if not len then len = #data end

		local p = self:alloc(len)
		ffi.copy(p,ffi.cast('char *',data),len)
	end

	function buf:clear(n)
		n = n or 0
		assert(n <= self.cur, "position must be less than current length")
		self.cur = n
	end

	function buf:dump()
		local p,len = self:pv()
		return M.xd(p,len,nil)
	end
	buf.xd = buf.dump

	function buf:hex()
		local p,len = self:pv()
		return M.hex(p,len)
	end

	do
		local rbuf = {}

		local function bin_rbuf_str( self )
			return string.format(
				'binrbuf<0x%x>[%s/%s]',
				tonumber(ffi.cast('int',ffi.cast('char *',self))),
				tonumber(self.p.c - self.buf),
				tonumber(self.len)
			)
		end

		local rbuf_t = ffi.typedef('bin_rbuf',[[
			typedef struct bin_rbuf {
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
			} bin_rbuf;
		]],{
			__index = rbuf;
			__tostring = bin_rbuf_str;
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

				rbuf[ typename ] = function(self)
					local n = self.p[typename][0]
					self.p[typename] = self.p[typename]+1
					return n
				end
				if sz > 1 then
					local htobe = 'bin_htobe' .. t
					local htole = 'bin_htole' .. t
					rbuf[ typename..'le' ] = function(self)
						local n = self.p[typename][0]
						self.p[typename] = self.p[typename]+1
						return lib[htole]( n )
					end
					rbuf[ typename..'be' ] = function(self)
						local n = self.p[typename][0]
						self.p[typename] = self.p[typename]+1
						return lib[htobe]( n )
					end
				end
			end
		end

		-- TODO: float, double

		rbuf.V = rbuf.i32le;
		rbuf.N = rbuf.i32be;

		function rbuf:reb()
			local n = ffi.new("uint64_t [1]", 0)
			local shift = C.reb_decode(self.p.u8, self:avail(), ffi.cast('uint64_t *', n))
			if shift == 0 then
				error("Decoding REB failed", 2)
			else
				self.p.u8 = self.p.u8 + shift
				return n[0]
			end
		end

		-- BER isn't supported for lower version of LuaJIT
		if jit_major >= "2.1" then
			function rbuf:ber()
				local n = 0ULL
				for i = 0,8 do
					n = bit.bor( bit.lshift(n,7), bit.band( 0x7f, self.p.u8[i] ) )
					if self.p.u8[i] < 0x80 then
						self.p.u8 = self.p.u8 + i + 1
						return n
					end
				end
				error("Bad BER sequence",2)
			end
		end

		function rbuf:str(len)
			local str = ffi.string( self.p.c, len )
			self.p.c = self.p.c + len
			return str
		end
		function rbuf:dump()
			return M.xd(self.p.c,self.len - (self.p.c-self.buf),nil)
		end

		function rbuf:hex()
			return M.hex(self.p.c,self.len - (self.p.c-self.buf))
		end

		function rbuf:move()
			C.memmove( self.buf, self.p.c, self.len - (self.p.c-self.buf) )
			self.p.c = self.buf
		end

		function rbuf:skip(len)
			self.p.c = self.p.c + len
		end

		function rbuf:avail()
			return self.len - (self.p.c-self.buf)
		end

		function M.rbuf(p,l)
			if not l then l = #p end
			local self = rbuf_t{ buf = p; len = l; }
			self.p.c = p;
			return self;
		end

		function buf:reader()
			local p,l = self:pv()
			-- print(p," ",l)
			return M.rbuf(p,l)
		end

	end

end -- base_buf

local base_buf = buf buf = nil

do -- fixbuf
	local buf = {}

	function buf:alloc( sz )
		-- print("alloc for buf ",self, sz, ffi.sizeof(self[0]))
		if ffi.sizeof(self[0]) - self.cur < sz then
			error("No more space in fixed buffer",2)
		end
		self.cur = self.cur + sz
		return ffi.cast('char *',self) + self.cur - sz
	end

	--[[
		* pv() doesn't grant ownership. you can't continue to use pointer
			after buffer modification or after free of original object
		* export() grants ownership of struct to the returned value (including gc).
			use object after export if prohibited
	]]

	function buf:pv()
		return ffi.cast('char *',self),self.cur
	end
	
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

	for k,v in pairs(base_buf) do buf[k] = v end

	local types = {}
	local sizes = {}
	-- 4k to 1Gb
	for i = 12,20 do
		local sz = 2^i
		local cap = sz - ffi.sizeof('size_t')
		local t = ffi.typedef('bin_buf_'..cap,
			'typedef struct bin_buf_'..cap..' { char buf['..cap..']; size_t cur; } bin_buf_'..cap..';'
			,{
				__index = buf;
				__tostring = bin_buf_str;
			}
		)
		types[cap] = t
		table.insert(sizes,cap)
	end

	function M.fixbuf(sz)
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

end

do -- buf
	local buf = {}

	local function capacity(sz)
		-- grow by 64b blocks or by 1/4 of data aligned by 64b
		sz = tonumber(sz)
		local alg = math.ceil(sz / 4 / 64) * 64
		return math.ceil(sz / alg) * alg
	end

	function buf:alloc( sz )
		-- print("alloc for buf ",self, sz)
		if self.len - self.cur < sz then
			self.len = capacity(self.cur + sz);
			-- print("realloc for buf ",self, sz)
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

	for k,v in pairs(base_buf) do buf[k] = v end

	local t = ffi.typedef('bin_buf',[[
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

	function M.buf(sz)
		sz = sz or 4096;
		-- sz = sz or 16;
		local b = ffi.new( 'bin_buf');
		b.len = capacity(sz);
		-- b.buf = ffi.new('char[?]',b.len) -- memory corruption after free ((
		b.buf = C.calloc(b.len,1) -- memory corruption after free ((
		return b
	end
end

return M
