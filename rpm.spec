%{!?lua_version: %global lua_version %{lua: print(string.sub(_VERSION, 5))}}
%define lua_version 5.1

%{!?lua_libdir: %global lua_libdir %{_libdir}/lua/%{lua_version}}
%{!?lua_pkgdir: %global lua_pkgdir %{_datadir}/lua/%{lua_version}}

%{!?luarocks_libdir: %global luarocks_libdir %(luarocks config --lua-libdir)}

%define __repo bin

Name:			lua-%{__repo}
Version:		3.1.1
Release:		1
License:		BSD
Group:			Development/Libraries
Url:			https://github.com/moonlibs/bin
Summary:		FFI-library
BuildArch:		x86_64
BuildRoot:		%{_tmppath}/%{name}
BuildRequires:  lua-ffi-reloadable >= 1
BuildRequires:  gcc
Requires:       lua-ffi-reloadable >= 1

%description
Binary tools for LuaJIT

%prep
rm -rf %{__repo}

%if %{?SRC_DIR:1}%{!?SRC_DIR:0}
	rm -rf %{__repo}
	mkdir -p %{__repo}
	cp -rai %{SRC_DIR}/* %{__repo}
	cd %{__repo}
%else
mkdir %{__repo}
%endif

%build

%install
cd %{__repo}
gcc -O2 -fPIC -I/usr/include/lua5.1 -c libluabin.c -o libluabin.o
gcc -shared -o libluabin-scm-3.so -L/usr/lib libluabin.o

install -d -m 0755 %{buildroot}/usr/share/lua/5.1/
install -d -m 0755 %{buildroot}/usr/lib64/lua/5.1/

install -m 0644 bin.lua   %{buildroot}/usr/share/lua/5.1/
install -m 0644 libluabin-scm-3.so  %{buildroot}/usr/lib64/lua/5.1/

%clean
rm -rf %{buildroot}
rm -rf %{__repo}

%files
%defattr(-,root,root)
%{_datadir}/lua/%{lua_version}/*
%{_prefix}/lib64/lua/5.1/

%changelog

