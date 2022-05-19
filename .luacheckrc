std = "luajit"
include_files = { "bin/", "bin.lua" }
codes = true
ignore = { "631" --[[ line is too long ]] }
read_globals = { 'package.search' }
