package = "bin"
version = "dev-1"

source  = {
    url    = 'git+https://github.com/moonlibs/bin.git';
    branch = 'master';
}

description = {
    summary  = "Binary tools";
    detailed = "Binary tools";
    homepage = 'https://github.com/moonlibs/bin.git';
    license  = 'Artistic';
    maintainer = "Mons Anderson <mons@cpan.org>";
}

dependencies = {
    'lua >= 5.1';
    'ffi-reloadable >= 0';
}

build = {
    type = "builtin",
    modules = {
        bin = "bin.lua",
        ["bin.base"] = "bin/base.lua",
        ["bin.basebuf"] = "bin/basebuf.lua",
        ["bin.buf"] = "bin/buf.lua",
        ["bin.fixbuf"] = "bin/fixbuf.lua",
        ["bin.rbuf"] = "bin/rbuf.lua",
        ["bin.saferbuf"] = "bin/saferbuf.lua",
        ['libluabin-scm-4'] = {
            sources = "libluabin.c"
        },
    },
}
