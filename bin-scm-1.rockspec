package = 'bin'
version = 'scm-1'

source  = {
    url    = 'git://github.com/moonlibs/bin.git';
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