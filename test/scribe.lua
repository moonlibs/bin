package.path = "./?.lua;"..package.path
print(package.searchpath('bin', package.path))

local bin = require 'bin'
local ffi = require 'ffi'

local function typedef(t,def)
	if not pcall(ffi.typeof,t) then
		local r,e = pcall(ffi.cdef,def)
		if not r then error(e,2) end
	end
	return ffi.typeof(t)
end
local function fundef(n,def,src)
	src = src or ffi.C
	local f = function(src,n) return src[n] end
	if not pcall(f,src,n) then
		local r,e = pcall(ffi.cdef,def)
		if not r then error(e,2) end
	end
	local r,e = pcall(f,src,n)
	if not r then
		error(e,2)
	end
	return r
end

local VERSION_MASK = ffi.cast('uint32_t',0xffff0000)
local VERSION_1    = ffi.cast('uint32_t',0x80010000);

local M_CALL       = 1
local M_REPLY      = 2
local M_EXCEPTION  = 3
local M_ONEWAY     = 4

local T_STOP       = 0
local T_VOID       = 1
local T_BOOL       = 2
local T_BYTE       = 3
-- local T_I08        = 3
local T_I16        = 6
local T_I32        = 8
local T_U64        = 9
local T_I64        = 10
local T_DOUBLE     = 4
local T_STRING     = 11
-- local T_UTF7       = 11
local T_STRUCT     = 12
local T_MAP        = 13
local T_SET        = 14
local T_LIST       = 15
local T_UTF8       = 16
local T_UTF16      = 1


typedef('sc_hdr_t',[[
#pragma pack (push, 1)
typedef struct {
	unsigned size : 32;
	char     v0   : 8;
	char     v1   : 8;
	char     t0   : 8;
	char     t1   : 8;
	char     len[4];
	char proc[3];

	unsigned seq  : 32;
	struct {
		unsigned char type;
		unsigned char id[2];
	} field;
	struct {
		unsigned char type;
		unsigned int  size : 32;
	} list;
} sc_hdr_t;
#pragma pack (pop)
]])

local def_hdr = ffi.new('sc_hdr_t',{
	size = 0;

	v0 = 0x80; v1 = 1;
	t0 = 0;	t1 = 1;

	len   = {0,0,0,3};
	proc  = "Log";

	field = { type = T_LIST,id={0,1} };
	list  = { T_STRUCT,0};
})
local HDR_SZ = ffi.sizeof('sc_hdr_t')

local _seq = 1233
function seq()
	_seq = _seq < 0xffffffff and _seq + 1 or 1
	return _seq
end


function send(...)
	local messages
	if type(...) == 'table' then
		local t = ...
		if #t == 0 then
			messages = {t}
		else
			messages = t
		end
	else
		local cat,msg = ...
		messages = {{cat=cat,msg=msg}}
	end

	local sz = HDR_SZ
	-- print(sz)
	for _,rec in pairs(messages) do
		if rec.cat then
			sz = sz+1+2+4+#rec.cat
		end
		if rec.msg then
			sz = sz+1+2+4+#rec.msg
		end
		sz = sz+1
	end
	sz = sz+1

	local buf = bin.fixbuf(sz)
	local hdr = ffi.cast( 'sc_hdr_t *', buf:alloc(HDR_SZ) )
	ffi.copy(hdr,def_hdr,HDR_SZ)

	local seq = seq()

	hdr.seq = bin.htobe32( seq )
	hdr.list.size = bin.htobe32( #messages )

	for _,rec in pairs(messages) do
		if rec.cat then
			buf:uint8(T_STRING)
			buf:uint16be(1)
			buf:uint32be(#rec.cat)
			buf:copy(rec.cat)
		end
		if rec.msg then
			buf:uint8(T_STRING)
			buf:uint16be(2)
			buf:uint32be(#rec.msg)
			buf:copy(rec.msg)
		end
		buf:uint8(0)
	end
	buf:uint8(0)

	local p,len = buf:pv()
	hdr = ffi.cast( 'sc_hdr_t *', p )
	hdr.size = bin.htobe32( len - 4 )

	local p,len,sz = buf:export()
	p = ffi.cast('char *',p)
end

for i=1,1000 do
	send({ cat = "category"; msg = "message" })
end
for i=1,1000 do
	send({ cat = "category"; msg = "message" })
	collectgarbage('collect')
end
