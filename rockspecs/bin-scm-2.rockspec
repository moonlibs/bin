package = 'bin'
version = 'scm-2'

source  = {
    url    = 'git+https://github.com/moonlibs/bin.git';
    branch = 'v2';
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
    type = 'builtin',
    modules = {
        ['bin'] = 'bin.lua';
        ['libluabin'] = {
            sources = {
                "libluabin.c",
            };
        }
    }
}
