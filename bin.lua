local M = {}
for method, func in pairs(require 'bin.base') do
	M[method] = func
end

M.fixbuf = require 'bin.fixbuf'.new
M.buf = require 'bin.buf'.new
M.rbuf = require 'bin.rbuf'.new
M.saferbuf = require 'bin.saferbuf'.new

return M
