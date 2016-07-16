#!/bin/bash
set -e

. common.sh

mkdir -p win32
cd win32

build_triplet=$(/usr/share/automake-1.15/config.guess)

install_native="$PWD/install-native"
install_win32="$PWD/install-win32"
#install_native="$PWD/install"
#install_win32="$install_native/i686-w64-mingw32"

mkdir -p "$install_native"
mkdir -p "$install_win32"

version_binutils="2.26"
version_gcc="6.1.0"
version_mingww64="4.0.6"
version_gmp="6.1.0"
version_mpfr="3.1.4"
version_mpc="1.0.3"
version_libffi="3.2.1"
version_fbc="1.05.0"

title_binutils="binutils-$version_binutils"
title_gcc="gcc-$version_gcc"
title_mingww64="mingw-w64-v$version_mingww64"
title_gmp="gmp-$version_gmp"
title_mpfr="mpfr-$version_mpfr"
title_mpc="mpc-$version_mpc"
title_libffi="libffi-$version_libffi"
title_fbc="FreeBASIC-$version_fbc-source"

tarball_binutils="$title_binutils.tar.bz2"
tarball_gcc="$title_gcc.tar.bz2"
tarball_mingww64="$title_mingww64.tar.bz2"
tarball_gmp="$title_gmp.tar.lz"
tarball_mpfr="$title_mpfr.tar.xz"
tarball_mpc="$title_mpc.tar.gz"
tarball_libffi="$title_libffi.tar.gz"
tarball_fbc="$title_fbc.tar.xz"

my_fetch "$tarball_binutils" "http://ftpmirror.gnu.org/binutils/$tarball_binutils"
my_fetch "$tarball_gcc"      "http://ftpmirror.gnu.org/gcc/$title_gcc/$tarball_gcc"
my_fetch "$tarball_mingww64" "https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/$tarball_mingww64/download"
my_fetch "$tarball_gmp"  "https://gmplib.org/download/gmp/$tarball_gmp"
my_fetch "$tarball_mpfr" "http://www.mpfr.org/mpfr-current/$tarball_mpfr"
my_fetch "$tarball_mpc"  "ftp://ftp.gnu.org/gnu/mpc/$tarball_mpc"
my_fetch "$tarball_libffi" "ftp://sourceware.org/pub/libffi/$tarball_libffi"
my_fetch "$tarball_fbc"  "https://sourceforge.net/projects/fbc/files/Source%20Code/$tarball_fbc/download"

my_extract "$title_binutils" "$tarball_binutils"
my_extract "$title_gcc"      "$tarball_gcc"
my_extract "$title_mingww64" "$tarball_mingww64"
my_extract "$title_gmp"      "$tarball_gmp"
my_extract "$title_mpfr"     "$tarball_mpfr"
my_extract "$title_mpc"      "$tarball_mpc"
my_extract "$title_libffi"   "$tarball_libffi"
my_extract "FreeBASIC-$version_fbc-native" "$tarball_fbc"
my_extract "FreeBASIC-$version_fbc-win32" "$tarball_fbc"
my_extract "fbc-$version_fbc-win32" "$tarball_fbc"

if [ ! -f "$title_gcc"/patch-done.stamp ]; then
	echo "patching: $title_gcc"
	cd "$title_gcc"

	# Fix precheck for fixincludes
	patch -p1 < ../../gcc-fixincludes-with-build-sysroot.patch

	# Disable fixincludes
	sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in

	touch patch-done.stamp
	cd ..
fi

export PATH="$install_native/bin:$PATH"

my_autotools_build() {
	title="$1"
	builddir="$2"
	confsubdir="$3"
	confargs="$4"
	maketarget="$5"
	makeinstalltarget="$6"
	if [ ! -f "$builddir/build-done.stamp" ]; then
		echo "build: $builddir"
		rm -rf "$builddir"
		mkdir "$builddir"
		cd "$builddir"
		( \
			set -x && \
			"../$title/${confsubdir}configure" --build=$build_triplet $confargs && \
			make $maketarget && \
			make $makeinstalltarget && \
			find "$install_native" "$install_win32" -type f -name "*.la" | xargs rm -f \
		) > build-log.txt 2>&1
		cd ..
		touch "$builddir/build-done.stamp"
	fi
}

my_autotools_build "$title_binutils" "$title_binutils-build-native-to-win32" \
	"" \
	"
		--target=i686-w64-mingw32
		--prefix=$install_native --with-sysroot=$install_win32
		--enable-static --disable-shared
		--disable-nls --disable-multilib --disable-werror
	" \
	"" install

my_autotools_build "$title_gmp" "$title_gmp-build-native" \
	"" \
	"--prefix=$install_native --enable-static --disable-shared" \
	"" install

my_autotools_build "$title_mpfr" "$title_mpfr-build-native" \
	"" \
	"--prefix=$install_native --enable-static --disable-shared
	 --with-gmp=$install_native" \
	"" install

my_autotools_build "$title_mpc" "$title_mpc-build-native" \
	"" \
	"--prefix=$install_native --enable-static --disable-shared
	 --with-gmp=$install_native --with-mpfr=$install_native" \
	"" install

my_autotools_build "$title_mingww64" "$title_mingww64-build-win32-headers" \
	"mingw-w64-headers/" \
	"--host=i686-w64-mingw32 --prefix=" \
	"" "install DESTDIR=$install_win32"

if [ ! -e "$install_win32/mingw" ]; then
	ln -s . "$install_win32/mingw"
fi

my_autotools_build "$title_gcc" "$title_gcc-build-native-to-win32" \
	"" \
	"
		--target=i686-w64-mingw32
		--prefix=$install_native
		--with-local-prefix=$install_native
		--with-sysroot=$install_win32
		--with-gmp=$install_native
		--with-mpfr=$install_native
		--with-mpc=$install_native
		--enable-static --disable-shared
		--disable-bootstrap --enable-languages=c,c++
		--disable-nls --disable-multilib
		--disable-lto --disable-lto-plugin
		--disable-libssp --disable-libquadmath
		--disable-libmudflap --disable-libgomp --disable-libatomic
		--disable-decimal-float
		--enable-threads=win32 --enable-sjlj-exceptions
	" \
	all-gcc install-gcc

my_autotools_build "$title_mingww64" "$title_mingww64-build-win32-crt" \
	"mingw-w64-crt/" \
	"--host=i686-w64-mingw32
	 --prefix=
	 --enable-wildcard" \
	"" "install DESTDIR=$install_win32"

pass2stamp="$title_gcc-build-native-to-win32/build-done-pass2.stamp"
if [ ! -e "$pass2stamp" ]; then
	echo "build: $title_gcc-build-native-to-win32 pass 2"
	cd "$title_gcc-build-native-to-win32"
	(make && make install) > build-log-pass2.txt 2>&1
	cd ..
	touch "$pass2stamp"
fi

my_autotools_build "$title_gmp" "$title_gmp-build-win32" \
	"" \
	"--host=i686-w64-mingw32
	 --prefix=
	 --enable-static --disable-shared" \
	"" "install DESTDIR=$install_win32"

my_autotools_build "$title_mpfr" "$title_mpfr-build-win32" \
	"" \
	"--host=i686-w64-mingw32
	 --prefix=
	 --enable-static --disable-shared
	 --with-gmp=$install_win32" \
	"" "install DESTDIR=$install_win32"

my_autotools_build "$title_mpc" "$title_mpc-build-win32" \
	"" \
	"--host=i686-w64-mingw32
	 --prefix=
	 --enable-static --disable-shared
	 --with-gmp=$install_win32 --with-mpfr=$install_win32" \
	"" "install DESTDIR=$install_win32"

my_autotools_build "$title_binutils" "$title_binutils-build-win32-to-win32" \
	"" \
	"
		--host=i686-w64-mingw32 --target=i686-w64-mingw32
		--prefix=
		--enable-static --disable-shared
		--disable-nls --disable-multilib --disable-werror
	" \
	"" "install DESTDIR=$install_win32"

my_autotools_build "$title_gcc" "$title_gcc-build-win32-to-win32" \
	"" \
	"
		--host=i686-w64-mingw32 --target=i686-w64-mingw32
		--prefix=
		--with-local-prefix=
		--with-build-sysroot=$install_win32
		--with-gmp=$install_win32
		--with-mpfr=$install_win32
		--with-mpc=$install_win32
		--enable-static --disable-shared
		--disable-bootstrap --enable-languages=c,c++
		--disable-nls --disable-multilib
		--disable-lto --disable-lto-plugin
		--disable-libssp --disable-libquadmath
		--disable-libmudflap --disable-libgomp --disable-libatomic
		--disable-decimal-float
		--enable-threads=win32 --enable-sjlj-exceptions
		--disable-win32-registry
	" \
	"" "install DESTDIR=$install_win32"

my_autotools_build "$title_libffi" "$title_libffi-build-win32" \
	"" \
	"
		--host=i686-w64-mingw32
		--prefix=
		--enable-static --disable-shared
	" \
	"" "install DESTDIR=$install_win32"

if [ ! -f "FreeBASIC-$version_fbc-native/build-done.stamp" ]; then
	echo "build: FreeBASIC-$version_fbc-native"
	cd "FreeBASIC-$version_fbc-native"
	( \
		set -x && \
		rm -f config.mk && \
		echo 'V := 1'                                                 >> config.mk && \
		echo "prefix := $install_native"                              >> config.mk && \
		echo 'ifeq ($(TARGET),i686-w64-mingw32)'                      >> config.mk && \
		echo "  CFLAGS += -I$install_win32/lib/$title_libffi/include" >> config.mk && \
		echo 'endif'                                                  >> config.mk && \
		make compiler && \
		make install-compiler install-includes && \
		make TARGET=i686-w64-mingw32 rtlib gfxlib2 && \
		make TARGET=i686-w64-mingw32 install-rtlib install-gfxlib2 \
	) > build-log.txt 2>&1
	cd ..
	touch "FreeBASIC-$version_fbc-native/build-done.stamp"
fi

if [ ! -f "FreeBASIC-$version_fbc-win32/build-done.stamp" ]; then
	echo "build: FreeBASIC-$version_fbc-win32"
	cd "FreeBASIC-$version_fbc-win32"
	( \
		set -x && \
		rm -f config.mk && \
		echo 'ENABLE_STANDALONE := 1'                               >> config.mk && \
		echo 'TARGET := i686-w64-mingw32'                           >> config.mk && \
		echo "CFLAGS += -I$install_win32/lib/$title_libffi/include" >> config.mk && \
		echo 'V := 1'                                               >> config.mk && \
		make \
	) > build-log.txt 2>&1
	cd ..
	touch "FreeBASIC-$version_fbc-win32/build-done.stamp"
fi

if [ ! -f "fbc-$version_fbc-win32/build-done.stamp" ]; then
	echo "build: fbc-$version_fbc-win32"
	cd "fbc-$version_fbc-win32"
	( \
		set -x && \
		rm -f config.mk && \
		echo 'TARGET := i686-w64-mingw32'                           >> config.mk && \
		echo "CFLAGS += -I$install_win32/lib/$title_libffi/include" >> config.mk && \
		echo 'V := 1'                                               >> config.mk && \
		make && \
		make install "prefix=$install_win32" \
	) > build-log.txt 2>&1
	cd ..
	touch "fbc-$version_fbc-win32/build-done.stamp"
fi

echo "stripping debug symbols"
find "$install_win32" -type f -name "*.exe" -or -name "*.dll" -or -name "*.a" -or -name "*.o" | \
	grep -v 'libruntimeobject\.a$' | \
	xargs i686-w64-mingw32-strip --strip-debug

echo "ok, done"
