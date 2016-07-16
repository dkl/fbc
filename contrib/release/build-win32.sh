#!/bin/bash
set -e

. common.sh

mkdir -p win32
cd win32

install_native="$PWD/install"
install_win32="$install_native/i686-w64-mingw32"
mkdir -p "$install_win32"
if [ ! -e "$install_win32/mingw" ]; then
	ln -s . "$install_win32/mingw"
fi
export PATH="$install_native/bin:$PATH"

version_binutils=2.26.1
version_fbc=327f5f6
version_fbc_git=yes
version_gcc=6.1.0
version_gmp=6.1.0
version_libffi=3.2.1
version_mingww64=4.0.6
version_mpc=1.0.3
version_mpfr=3.1.4

title_binutils=binutils-$version_binutils
title_gcc=gcc-$version_gcc
title_gmp=gmp-$version_gmp
title_libffi=libffi-$version_libffi
title_mingww64=mingw-w64-v$version_mingww64
title_mpc=mpc-$version_mpc
title_mpfr=mpfr-$version_mpfr

tarball_binutils=$title_binutils.tar.bz2
tarball_gcc=$title_gcc.tar.bz2
tarball_gmp=$title_gmp.tar.lz
tarball_libffi=$title_libffi.tar.gz
tarball_mingww64=$title_mingww64.tar.bz2
tarball_mpc=$title_mpc.tar.gz
tarball_mpfr=$title_mpfr.tar.xz

my_fetch $tarball_binutils "http://ftpmirror.gnu.org/binutils/$tarball_binutils"
my_fetch $tarball_gcc      "http://ftpmirror.gnu.org/gcc/$title_gcc/$tarball_gcc"
my_fetch $tarball_gmp      "https://gmplib.org/download/gmp/$tarball_gmp"
my_fetch $tarball_libffi   "ftp://sourceware.org/pub/libffi/$tarball_libffi"
my_fetch $tarball_mingww64 "https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/$tarball_mingww64/download"
my_fetch $tarball_mpc      "ftp://ftp.gnu.org/gnu/mpc/$tarball_mpc"
my_fetch $tarball_mpfr     "http://www.mpfr.org/mpfr-current/$tarball_mpfr"

if [ "$version_fbc_git" = "yes" ]; then
	title_fbc=fbc-$version_fbc
	tarball_fbc=$title_fbc.tar.gz
	my_fetch $tarball_fbc "https://github.com/freebasic/fbc/archive/$version_fbc.tar.gz"
else
	title_fbc=FreeBASIC-$version_fbc-source
	tarball_fbc=$title_fbc.tar.xz
	my_fetch $tarball_fbc "https://sourceforge.net/projects/fbc/files/Source%20Code/$tarball_fbc/download"
fi

my_extract $title_binutils $tarball_binutils
my_extract $title_fbc      $tarball_fbc
my_extract $title_gcc      $tarball_gcc
my_extract $title_gmp      $tarball_gmp
my_extract $title_libffi   $tarball_libffi
my_extract $title_mingww64 $tarball_mingww64
my_extract $title_mpc      $tarball_mpc
my_extract $title_mpfr     $tarball_mpfr

################################################################################

do_patch() {
	srcdirname="$1"
	case "$srcdirname" in
	gcc-*)
		# Fix precheck for fixincludes
		patch -p1 < ../../gcc-fixincludes-with-build-sysroot.patch
		# Disable fixincludes
		sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in
		;;
	esac
}

maybe_do_patch() {
	srcdirname="$1"
	if [ ! -f "$srcdirname/patch-done.stamp" ]; then
		echo "patch: $srcdirname"
		cd "$srcdirname"
		do_patch "$srcdirname" > patch-log.txt 2>&1
		touch patch-done.stamp
		cd ..
	fi
}

maybe_do_patch $title_gcc

################################################################################

do_build_autotools_native() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=$build_triplet \
		--prefix="$install_native" \
		--enable-static --disable-shared "$@"
	make
	make install
}

do_build_autotools_win32() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=i686-w64-mingw32 \
		--prefix= \
		--enable-static --disable-shared "$@"
	make
	make install DESTDIR="$install_win32"
}

do_build() {
	local buildname="$1"

	case "$buildname" in

	$title_binutils-build-native-to-win32)
		do_build_autotools_native $title_binutils \
			--target=i686-w64-mingw32 --with-sysroot="$install_win32" \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_binutils-build-win32-to-win32)
		do_build_autotools_win32 $title_binutils \
			--target=i686-w64-mingw32 \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_mingww64-build-win32-headers)
		../$title_mingww64/mingw-w64-headers/configure \
			--build=$build_triplet --host=i686-w64-mingw32 \
			--prefix=
		make
		make install DESTDIR="$install_win32"
		;;

	$title_mingww64-build-win32-crt)
		../$title_mingww64/mingw-w64-crt/configure \
			--build=$build_triplet --host=i686-w64-mingw32 \
			--prefix= \
			--enable-wildcard
		make
		make install DESTDIR="$install_win32"
		;;

	$title_gcc-build-native-to-win32-gcc)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i686-w64-mingw32 \
			--prefix="$install_native" \
			--with-local-prefix="$install_native" \
			--with-sysroot="$install_win32" \
			--with-gmp="$install_native" \
			--with-mpfr="$install_native" \
			--with-mpc="$install_native" \
			--enable-static --disable-shared \
			--disable-bootstrap --enable-languages=c,c++ \
			--disable-nls --disable-multilib \
			--disable-lto --disable-lto-plugin \
			--disable-libssp --disable-libquadmath \
			--disable-libmudflap --disable-libgomp --disable-libatomic \
			--disable-decimal-float \
			--enable-threads=win32 --enable-sjlj-exceptions
		make all-gcc
		make install-gcc
		;;

	$title_gcc-build-native-to-win32-full)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i686-w64-mingw32 \
			--prefix="$install_native" \
			--with-local-prefix="$install_native" \
			--with-sysroot="$install_win32" \
			--with-gmp="$install_native" \
			--with-mpfr="$install_native" \
			--with-mpc="$install_native" \
			--enable-static --disable-shared \
			--disable-bootstrap --enable-languages=c,c++ \
			--disable-nls --disable-multilib \
			--disable-lto --disable-lto-plugin \
			--disable-libssp --disable-libquadmath \
			--disable-libmudflap --disable-libgomp --disable-libatomic \
			--disable-decimal-float \
			--enable-threads=win32 --enable-sjlj-exceptions
		make
		make install
		;;

	$title_gcc-build-win32-to-win32)
		do_build_autotools_win32 $title_gcc \
			--target=i686-w64-mingw32 \
			--with-local-prefix= \
			--with-build-sysroot="$install_win32" \
			--with-gmp="$install_win32" \
			--with-mpfr="$install_win32" \
			--with-mpc="$install_win32" \
			--disable-bootstrap --enable-languages=c,c++ \
			--disable-nls --disable-multilib \
			--disable-lto --disable-lto-plugin \
			--disable-libssp --disable-libquadmath \
			--disable-libmudflap --disable-libgomp --disable-libatomic \
			--disable-decimal-float \
			--enable-threads=win32 --enable-sjlj-exceptions \
			--disable-win32-registry
		;;

	fbc-*-build-native)
		rm -f config.mk
		echo 'V := 1'                                                 >> config.mk
		echo 'ifeq ($(TARGET),i686-w64-mingw32)'                      >> config.mk
		echo "  CFLAGS += -I\"$install_win32/lib/$title_libffi/include\"" >> config.mk
		echo 'endif'                                                  >> config.mk
		echo "prefix := $install_native"                              >> config.mk
		make -f ../$title_fbc/makefile compiler install-compiler install-includes
		make -f ../$title_fbc/makefile TARGET=i686-w64-mingw32 rtlib gfxlib2 install-rtlib install-gfxlib2
		;;

	fbc-*-build-win32)
		rm -f config.mk
		echo 'V := 1'                                               >> config.mk
		echo 'TARGET := i686-w64-mingw32'                           >> config.mk
		echo "CFLAGS += -I\"$install_win32/lib/$title_libffi/include\"" >> config.mk
		echo "prefix := $install_win32"                             >> config.mk
		make -f ../$title_fbc/makefile all install DESTDIR="$install_win32"
		;;

	fbc-*-build-win32-standalone)
		rm -f config.mk
		echo 'V := 1'                                                 >> config.mk
		echo 'TARGET := i686-w64-mingw32'                             >> config.mk
		echo "CFLAGS += -I\"$install_win32/lib/$title_libffi/include\"" >> config.mk
		echo 'ENABLE_STANDALONE := 1'                                 >> config.mk
		make -f ../$title_fbc/makefile
		;;

	$title_gmp-build-native)  do_build_autotools_native $title_gmp;;
	$title_mpfr-build-native) do_build_autotools_native $title_mpfr --with-gmp="$install_native";;
	$title_mpc-build-native)  do_build_autotools_native $title_mpc  --with-gmp="$install_native" --with-mpfr="$install_native";;

	$title_gmp-build-win32)    do_build_autotools_win32 $title_gmp;;
	$title_mpfr-build-win32)   do_build_autotools_win32 $title_mpfr --with-gmp="$install_win32";;
	$title_mpc-build-win32)    do_build_autotools_win32 $title_mpc  --with-gmp="$install_win32" --with-mpfr="$install_win32";;
	$title_libffi-build-win32) do_build_autotools_win32 $title_libffi;;

	*)
		echo "TODO: build $buildname"
		exit 1
		;;
	esac
}

maybe_do_build() {
	buildname="$1"

	if [ ! -f "$buildname/build-done.stamp" ]; then
		printf "build: $buildname "
		rm -rf "$buildname"
		mkdir "$buildname"
		cd "$buildname"

		if do_build "$buildname" > build-log.txt 2>&1; then
			printf '%s%s%s\n' "$term_color_green" "ok" "$term_color_reset"
		else
			printf '%s%s%s\n' "$term_color_red"   "fail" "$term_color_reset"
			exit 1
		fi
		remove_la_files_in_dirs "$install_native"

		cd ..
		touch "$buildname/build-done.stamp"
	fi
}

# cross toolchain
maybe_do_build $title_binutils-build-native-to-win32
maybe_do_build $title_gmp-build-native
maybe_do_build $title_mpfr-build-native
maybe_do_build $title_mpc-build-native
maybe_do_build $title_mingww64-build-win32-headers
maybe_do_build $title_gcc-build-native-to-win32-gcc
maybe_do_build $title_mingww64-build-win32-crt
maybe_do_build $title_gcc-build-native-to-win32-full
maybe_do_build $title_libffi-build-win32
maybe_do_build fbc-$version_fbc-build-native

maybe_do_build $title_gmp-build-win32
maybe_do_build $title_mpfr-build-win32
maybe_do_build $title_mpc-build-win32

maybe_do_build $title_binutils-build-win32-to-win32
maybe_do_build $title_gcc-build-win32-to-win32
maybe_do_build fbc-$version_fbc-build-win32
maybe_do_build fbc-$version_fbc-build-win32-standalone

################################################################################

# TODO: copy binaries from install dir into packaging dir, and then strip there
# for non-debug packages
echo "stripping debug symbols"
find "$install_win32" -type f -name "*.exe" -or -name "*.dll" -or -name "*.a" -or -name "*.o" | \
	grep -v 'libruntimeobject\.a$' | \
	xargs i686-w64-mingw32-strip --strip-debug

echo "ok, done"