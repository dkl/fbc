#!/bin/bash
#
# Requirements:
#  wget, unzip, xz-utils, lzip
#  gcc, g++, bison, flex, texinfo (makeinfo),
#  zlib-dev
#

set -e

. common.sh

mkdir -p build
cd build

version_binutils=2.27
version_fbc=25cf58cf29233fb8f010843fd0d1e07a63495f65
version_fbc_git=yes
version_gcc=6.2.0
version_gmp=6.1.1
version_libffi=3.2.1
version_mingww64=4.0.6
version_mpc=1.0.3
version_mpfr=3.1.4
version_zlib=1.2.8

title_binutils=binutils-$version_binutils
title_djbnu=bnu226sr3
title_djcrx=djcrx205
title_djgcc=gcc620s
title_djlsr=djlsr205
title_gcc=gcc-$version_gcc
title_gmp=gmp-$version_gmp
title_libffi=libffi-$version_libffi
title_mingww64=mingw-w64-v$version_mingww64
title_mpc=mpc-$version_mpc
title_mpfr=mpfr-$version_mpfr
title_zlib=zlib-$version_zlib

tarball_binutils=$title_binutils.tar.bz2
tarball_djbnu=$title_djbnu.zip
tarball_djcrx=$title_djcrx.zip
tarball_djgcc=$title_djgcc.zip
tarball_djlsr=$title_djlsr.zip
tarball_gcc=$title_gcc.tar.bz2
tarball_gmp=$title_gmp.tar.lz
tarball_libffi=$title_libffi.tar.gz
tarball_mingww64=$title_mingww64.tar.bz2
tarball_mpc=$title_mpc.tar.gz
tarball_mpfr=$title_mpfr.tar.xz
tarball_zlib=$title_zlib.tar.xz

my_fetch $tarball_binutils "http://ftpmirror.gnu.org/binutils/$tarball_binutils"
my_fetch $tarball_djbnu    "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/v2gnu/$tarball_djbnu"
my_fetch $tarball_djcrx    "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/$tarball_djcrx"
my_fetch $tarball_djgcc    "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2gnu/$tarball_djgcc"
my_fetch $tarball_djlsr    "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/$tarball_djlsr"
my_fetch $tarball_gcc      "http://ftpmirror.gnu.org/gcc/$title_gcc/$tarball_gcc"
my_fetch $tarball_gmp      "https://gmplib.org/download/gmp/$tarball_gmp"
my_fetch $tarball_libffi   "ftp://sourceware.org/pub/libffi/$tarball_libffi"
my_fetch $tarball_mingww64 "https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/$tarball_mingww64/download"
my_fetch $tarball_mpc      "ftp://ftp.gnu.org/gnu/mpc/$tarball_mpc"
my_fetch $tarball_mpfr     "http://www.mpfr.org/mpfr-current/$tarball_mpfr"
my_fetch $tarball_zlib     "http://zlib.net/$tarball_zlib"

if [ "$version_fbc_git" = "yes" ]; then
	title_fbc=fbc-$version_fbc
	tarball_fbc=$title_fbc.tar.gz
	my_fetch $tarball_fbc "https://github.com/freebasic/fbc/archive/$version_fbc.tar.gz"
else
	title_fbc=FreeBASIC-$version_fbc-source
	tarball_fbc=$title_fbc.tar.xz
	my_fetch $tarball_fbc "https://sourceforge.net/projects/fbc/files/Source%20Code/$tarball_fbc/download"
fi

if [ ! -f ../downloads/config.guess ]; then
	wget -O ../downloads/config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
	chmod +x ../downloads/config.guess
fi

my_extract $title_binutils $tarball_binutils
my_extract $title_djbnu    $tarball_djbnu
my_extract $title_djcrx    $tarball_djcrx
my_extract $title_djgcc    $tarball_djgcc
my_extract $title_djlsr    $tarball_djlsr
my_extract $title_fbc      $tarball_fbc
my_extract $title_gcc      $tarball_gcc
my_extract $title_gmp      $tarball_gmp
my_extract $title_libffi   $tarball_libffi
my_extract $title_mingww64 $tarball_mingww64
my_extract $title_mpc      $tarball_mpc
my_extract $title_mpfr     $tarball_mpfr
my_extract $title_zlib     $tarball_zlib

################################################################################

install_native="$PWD/install"
install_win32="$install_native/i686-w64-mingw32"
install_win64="$install_native/x86_64-w64-mingw32"
install_dos="$install_native/i586-pc-msdosdjgpp"
mkdir -p "$install_win32"
mkdir -p "$install_win64"
mkdir -p "$install_dos"
if [ ! -e "$install_win32/mingw" ]; then
	ln -s "$install_win32" "$install_win32/mingw"
fi
if [ ! -e "$install_win64/mingw" ]; then
	ln -s "$install_win64" "$install_win64/mingw"
fi
if [ ! -e "$install_dos/dev/env/DJDIR" ]; then
	mkdir -p "$install_dos/dev/env"
	ln -s "$install_dos" "$install_dos/dev/env/DJDIR"
fi
mkdir -p "$install_dos"/include
if [ ! -e "$install_dos"/sys-include ]; then
	ln -s "$install_dos"/include "$install_dos"/sys-include
fi

export PATH="$install_native/bin:$PATH"
export CFLAGS="-O2 -g0"
export CXXFLAGS="-O2 -g0"
cpucount="$(grep -c '^processor' /proc/cpuinfo)"
build_triplet=$(../downloads/config.guess)

################################################################################

do_patch() {
	srcdirname="$1"
	case "$srcdirname" in
	$title_djbnu)
		cp -R gnu/binutils-*/. .
		rm -rf gnu manifest
		chmod +x configure
		;;

	$title_djgcc)
		cp -R gnu/gcc-*/. .
		rm -rf gnu manifest
		chmod +x configure

		# Fix precheck for fixincludes
		patch -p1 < ../../gcc-fixincludes-with-build-sysroot.patch

		# Disable fixincludes
		sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in
		;;

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

maybe_do_patch $title_djbnu
maybe_do_patch $title_djgcc
maybe_do_patch $title_gcc

################################################################################

do_build_autotools_native() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=$build_triplet \
		--prefix="$install_native" \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install
}

do_build_autotools_win32() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=i686-w64-mingw32 \
		--prefix= \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$install_win32"
}

do_build_autotools_win64() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=x86_64-w64-mingw32 \
		--prefix= \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$install_win64"
}

do_build_autotools_dos() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=i586-pc-msdosdjgpp \
		--prefix= \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$install_dos"
}

do_build() {
	local buildname="$1"

	case "$buildname" in

	$title_binutils-build-native-to-win32)
		do_build_autotools_native $title_binutils \
			--target=i686-w64-mingw32 --with-sysroot="$install_win32" \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_binutils-build-native-to-win64)
		do_build_autotools_native $title_binutils \
			--target=x86_64-w64-mingw32 --with-sysroot="$install_win64" \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_djbnu-build-native-to-dos)
		do_build_autotools_native $title_djbnu \
			--target=i586-pc-msdosdjgpp --with-sysroot="$install_dos" \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_binutils-build-win32-to-win32)
		do_build_autotools_win32 $title_binutils \
			--target=i686-w64-mingw32 \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_binutils-build-win64-to-win64)
		do_build_autotools_win64 $title_binutils \
			--target=x86_64-w64-mingw32 \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_djbnu-build-dos-to-dos)
		do_build_autotools_dos $title_djbnu \
			--target=i586-pc-msdosdjgpp \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_mingww64-build-win32-headers)
		../$title_mingww64/mingw-w64-headers/configure \
			--build=$build_triplet --host=i686-w64-mingw32 \
			--prefix=
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$install_win32"
		;;

	$title_mingww64-build-win64-headers)
		../$title_mingww64/mingw-w64-headers/configure \
			--build=$build_triplet --host=x86_64-w64-mingw32 \
			--prefix=
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$install_win64"
		;;

	$title_mingww64-build-win32-crt)
		../$title_mingww64/mingw-w64-crt/configure \
			--build=$build_triplet --host=i686-w64-mingw32 \
			--prefix= \
			--enable-wildcard
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$install_win32"
		;;

	$title_mingww64-build-win64-crt)
		../$title_mingww64/mingw-w64-crt/configure \
			--build=$build_triplet --host=x86_64-w64-mingw32 \
			--prefix= \
			--enable-wildcard
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$install_win64"
		;;

	$title_djcrx-build-dos)
		cp -R ../$title_djcrx/. .
		cp -R ../$title_djlsr/. .
		find . -type f -name "*.o" -or -name "*.a" | xargs rm
		cd src
		rm -f *.opt
		sed -i 's/-Werror//g' makefile.cfg
		make
		cd ..
		cp -R include/. "$install_dos"/include
		cp lib/*.a lib/*.o "$install_dos"/lib
		install -m 0755 hostbin/stubify.exe "$install_native"/bin/stubify
		install -m 0755 hostbin/stubedit.exe "$install_native"/bin/stubedit
		install -m 0755 hostbin/dxegen.exe "$install_native"/bin/dxegen
		;;

	$title_gcc-build-native-to-win32-gcc)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i686-w64-mingw32 \
			--prefix="$install_native" \
			--with-sysroot="$install_win32" \
			--with-gmp="$install_native" \
			--with-mpfr="$install_native" \
			--with-mpc="$install_native" \
			--enable-static --disable-shared \
			--disable-bootstrap --enable-languages=c \
			--disable-nls --disable-multilib \
			--disable-lto --disable-lto-plugin \
			--disable-libssp --disable-libquadmath \
			--disable-libmudflap --disable-libgomp --disable-libatomic \
			--disable-decimal-float \
			--enable-threads=win32 --enable-sjlj-exceptions
		make -j"$cpucount" all-gcc
		make -j"$cpucount" install-gcc
		rm -f "$install_native"/lib/gcc/i586-pc-msdosdjgpp/?.?.?/include-fixed/*
		;;

	$title_gcc-build-native-to-win64-gcc)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=x86_64-w64-mingw32 \
			--prefix="$install_native" \
			--with-sysroot="$install_win64" \
			--with-gmp="$install_native" \
			--with-mpfr="$install_native" \
			--with-mpc="$install_native" \
			--enable-static --disable-shared \
			--disable-bootstrap --enable-languages=c \
			--disable-nls --disable-multilib \
			--disable-lto --disable-lto-plugin \
			--disable-libssp --disable-libquadmath \
			--disable-libmudflap --disable-libgomp --disable-libatomic \
			--disable-decimal-float \
			--enable-threads=win32 --enable-sjlj-exceptions
		make -j"$cpucount" all-gcc
		make -j"$cpucount" install-gcc
		;;

	$title_djgcc-build-native-to-dos-gcc)
		../$title_djgcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i586-pc-msdosdjgpp \
			--prefix="$install_native" \
			--with-sysroot="$install_dos" \
			--with-gmp="$install_native" \
			--with-mpfr="$install_native" \
			--with-mpc="$install_native" \
			--enable-static --disable-shared \
			--disable-bootstrap --enable-languages=c \
			--disable-nls --disable-multilib \
			--disable-lto --disable-lto-plugin \
			--disable-libssp --disable-libquadmath \
			--disable-libmudflap --disable-libgomp --disable-libatomic \
			--disable-decimal-float
		make -j"$cpucount" all-gcc
		make -j"$cpucount" install-gcc
		;;

	$title_gcc-build-native-to-win32-full)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i686-w64-mingw32 \
			--prefix="$install_native" \
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
		make -j"$cpucount"
		make -j"$cpucount" install
		;;

	$title_gcc-build-native-to-win64-full)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=x86_64-w64-mingw32 \
			--prefix="$install_native" \
			--with-sysroot="$install_win64" \
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
		make -j"$cpucount"
		make -j"$cpucount" install
		;;

	$title_djgcc-build-native-to-dos-full)
		../$title_djgcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i586-pc-msdosdjgpp \
			--prefix="$install_native" \
			--with-sysroot="$install_dos" \
			--with-gmp="$install_native" \
			--with-mpfr="$install_native" \
			--with-mpc="$install_native" \
			--enable-static --disable-shared \
			--disable-bootstrap --enable-languages=c,c++ \
			--disable-nls --disable-multilib \
			--disable-lto --disable-lto-plugin \
			--disable-libssp --disable-libquadmath \
			--disable-libmudflap --disable-libgomp --disable-libatomic \
			--disable-decimal-float
		make -j"$cpucount"
		make -j"$cpucount" install
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

	$title_gcc-build-win64-to-win64)
		do_build_autotools_win64 $title_gcc \
			--target=x86_64-w64-mingw32 \
			--with-local-prefix= \
			--with-build-sysroot="$install_win64" \
			--with-gmp="$install_win64" \
			--with-mpfr="$install_win64" \
			--with-mpc="$install_win64" \
			--disable-bootstrap --enable-languages=c,c++ \
			--disable-nls --disable-multilib \
			--disable-lto --disable-lto-plugin \
			--disable-libssp --disable-libquadmath \
			--disable-libmudflap --disable-libgomp --disable-libatomic \
			--disable-decimal-float \
			--enable-threads=win32 --enable-sjlj-exceptions \
			--disable-win32-registry
		;;

	$title_djgcc-build-dos-to-dos)
		ac_cv_c_bigendian=no \
		do_build_autotools_dos $title_djgcc \
			--target=i586-pc-msdosdjgpp \
			--with-local-prefix= \
			--with-build-sysroot="$install_dos" \
			--with-gmp="$install_dos" \
			--with-mpfr="$install_dos" \
			--with-mpc="$install_dos" \
			--disable-bootstrap --enable-languages=c,c++ \
			--disable-nls --disable-multilib \
			--disable-lto --disable-lto-plugin \
			--disable-libssp --disable-libquadmath \
			--disable-libmudflap --disable-libgomp --disable-libatomic \
			--disable-decimal-float
		;;

	fbc-*-build-native)
		rm -f config.mk
		echo 'V := 1'                                                 >> config.mk
		echo 'ifeq ($(TARGET),i686-w64-mingw32)'                      >> config.mk
		echo "  CFLAGS += -I\"$install_win32/lib/$title_libffi/include\"" >> config.mk
		echo 'endif'                                                  >> config.mk
		echo 'ifeq ($(TARGET),x86_64-w64-mingw32)'                    >> config.mk
		echo "  CFLAGS += -I\"$install_win64/lib/$title_libffi/include\"" >> config.mk
		echo 'endif'                                                  >> config.mk
		echo "prefix := $install_native"                              >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile compiler install-compiler install-includes
		make -j"$cpucount" -f ../$title_fbc/makefile TARGET=i686-w64-mingw32   rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../$title_fbc/makefile TARGET=x86_64-w64-mingw32 rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../$title_fbc/makefile TARGET=i586-pc-msdosdjgpp rtlib gfxlib2 install-rtlib install-gfxlib2
		;;

	fbc-*-build-win32)
		rm -f config.mk
		echo 'V := 1'                                               >> config.mk
		echo 'TARGET := i686-w64-mingw32'                           >> config.mk
		echo "CFLAGS += -I\"$install_win32/lib/$title_libffi/include\"" >> config.mk
		echo "prefix :="                                            >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile all install DESTDIR="$install_win32"
		;;

	fbc-*-build-win64)
		rm -f config.mk
		echo 'V := 1'                                               >> config.mk
		echo 'TARGET := x86_64-w64-mingw32'                         >> config.mk
		echo "CFLAGS += -I\"$install_win64/lib/$title_libffi/include\"" >> config.mk
		echo "prefix :="                                            >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile all install DESTDIR="$install_win64"
		;;

	fbc-*-build-dos)
		rm -f config.mk
		echo 'V := 1'                                               >> config.mk
		echo 'TARGET := i586-pc-msdosdjgpp'                         >> config.mk
		echo "prefix :="                                            >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile all install DESTDIR="$install_dos"
		;;

	fbc-*-build-win32-standalone)
		rm -f config.mk
		echo 'V := 1'                                                 >> config.mk
		echo 'TARGET := i686-w64-mingw32'                             >> config.mk
		echo "CFLAGS += -I\"$install_win32/lib/$title_libffi/include\"" >> config.mk
		echo 'ENABLE_STANDALONE := 1'                                 >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile
		;;

	fbc-*-build-win64-standalone)
		rm -f config.mk
		echo 'V := 1'                                                 >> config.mk
		echo 'TARGET := x86_64-w64-mingw32'                           >> config.mk
		echo "CFLAGS += -I\"$install_win64/lib/$title_libffi/include\"" >> config.mk
		echo 'ENABLE_STANDALONE := 1'                                 >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile
		;;

	fbc-*-build-dos-standalone)
		rm -f config.mk
		echo 'V := 1'                                                 >> config.mk
		echo 'TARGET := i586-pc-msdosdjgpp'                           >> config.mk
		echo 'ENABLE_STANDALONE := 1'                                 >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile
		;;

	$title_gmp-build-native)  do_build_autotools_native $title_gmp;;
	$title_mpfr-build-native) do_build_autotools_native $title_mpfr --with-gmp="$install_native";;
	$title_mpc-build-native)  do_build_autotools_native $title_mpc  --with-gmp="$install_native" --with-mpfr="$install_native";;

	$title_gmp-build-win32)    do_build_autotools_win32 $title_gmp;;
	$title_mpfr-build-win32)   do_build_autotools_win32 $title_mpfr --with-gmp="$install_win32";;
	$title_mpc-build-win32)    do_build_autotools_win32 $title_mpc  --with-gmp="$install_win32" --with-mpfr="$install_win32";;
	$title_libffi-build-win32) do_build_autotools_win32 $title_libffi;;

	$title_gmp-build-win64)    do_build_autotools_win64 $title_gmp;;
	$title_mpfr-build-win64)   do_build_autotools_win64 $title_mpfr --with-gmp="$install_win64";;
	$title_mpc-build-win64)    do_build_autotools_win64 $title_mpc  --with-gmp="$install_win64" --with-mpfr="$install_win64";;
	$title_libffi-build-win64) do_build_autotools_win64 $title_libffi;;

	$title_gmp-build-dos)    do_build_autotools_dos $title_gmp;;
	$title_mpfr-build-dos)   do_build_autotools_dos $title_mpfr --with-gmp="$install_dos";;
	$title_mpc-build-dos)    do_build_autotools_dos $title_mpc  --with-gmp="$install_dos" --with-mpfr="$install_dos";;
	$title_zlib-build-dos)
		cp -R ../$title_zlib/. .
		CHOST=i586-pc-msdosdjgpp ./configure --static --prefix=
		make
		make install DESTDIR="$install_dos"
		;;

	*)
		echo "TODO: build $buildname"
		exit 1
		;;
	esac
}

maybe_do_build() {
	buildname="$1"

	if [ ! -f "$buildname/build-done.stamp" ]; then
		echo "build: $buildname"
		rm -rf "$buildname"
		mkdir "$buildname"
		cd "$buildname"
		do_build "$buildname" > build-log.txt 2>&1
		remove_la_files_in_dirs "$install_native"
		cd ..
		touch "$buildname/build-done.stamp"
	fi
}

# cross toolchain and needed target libs
maybe_do_build $title_binutils-build-native-to-win32
maybe_do_build $title_binutils-build-native-to-win64
maybe_do_build $title_djbnu-build-native-to-dos
maybe_do_build $title_gmp-build-native
maybe_do_build $title_mpfr-build-native
maybe_do_build $title_mpc-build-native
maybe_do_build $title_mingww64-build-win32-headers
maybe_do_build $title_mingww64-build-win64-headers
maybe_do_build $title_gcc-build-native-to-win32-gcc
maybe_do_build $title_gcc-build-native-to-win64-gcc
maybe_do_build $title_djgcc-build-native-to-dos-gcc
maybe_do_build $title_mingww64-build-win32-crt
maybe_do_build $title_mingww64-build-win64-crt
maybe_do_build $title_djcrx-build-dos
maybe_do_build $title_gcc-build-native-to-win32-full
maybe_do_build $title_gcc-build-native-to-win64-full
maybe_do_build $title_djgcc-build-native-to-dos-full
maybe_do_build $title_libffi-build-win32
maybe_do_build $title_libffi-build-win64
maybe_do_build fbc-$version_fbc-build-native

# more target libs
maybe_do_build $title_gmp-build-win32
maybe_do_build $title_gmp-build-win64
maybe_do_build $title_gmp-build-dos
maybe_do_build $title_mpfr-build-win32
maybe_do_build $title_mpfr-build-win64
maybe_do_build $title_mpfr-build-dos
maybe_do_build $title_mpc-build-win32
maybe_do_build $title_mpc-build-win64
maybe_do_build $title_mpc-build-dos
maybe_do_build $title_zlib-build-dos

maybe_do_build $title_binutils-build-win32-to-win32
maybe_do_build $title_binutils-build-win64-to-win64
maybe_do_build $title_djbnu-build-dos-to-dos
maybe_do_build $title_gcc-build-win32-to-win32
maybe_do_build $title_gcc-build-win64-to-win64
maybe_do_build $title_djgcc-build-dos-to-dos
maybe_do_build fbc-$version_fbc-build-win32
maybe_do_build fbc-$version_fbc-build-win64
maybe_do_build fbc-$version_fbc-build-dos
maybe_do_build fbc-$version_fbc-build-win32-standalone
maybe_do_build fbc-$version_fbc-build-win64-standalone
maybe_do_build fbc-$version_fbc-build-dos

echo "ok"
