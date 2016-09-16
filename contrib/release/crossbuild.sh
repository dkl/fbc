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
version_fbc=246172c59e6db0bb77811e10b70c2963237f2ee6
version_fbc_git=yes
version_gcc=6.2.0
version_gmp=6.1.1
version_gpm=1.99.7
version_libffi=3.2.1
version_linux=4.7.3
version_mingww64=4.0.6
version_mpc=1.0.3
version_mpfr=3.1.4
version_musl=1.1.15
version_ncurses=6.0
version_zlib=1.2.8

title_binutils=binutils-$version_binutils
title_djbnu=bnu226sr3
title_djcrx=djcrx205
title_djgcc=gcc620s
title_djlsr=djlsr205
title_gcc=gcc-$version_gcc
title_gmp=gmp-$version_gmp
title_gpm=gpm-$version_gpm
title_libffi=libffi-$version_libffi
title_linux=linux-$version_linux
title_mingww64=mingw-w64-v$version_mingww64
title_mpc=mpc-$version_mpc
title_mpfr=mpfr-$version_mpfr
title_musl=musl-$version_musl
title_ncurses=ncurses-$version_ncurses
title_zlib=zlib-$version_zlib

tarball_binutils=$title_binutils.tar.bz2
tarball_djbnu=$title_djbnu.zip
tarball_djcrx=$title_djcrx.zip
tarball_djgcc=$title_djgcc.zip
tarball_djlsr=$title_djlsr.zip
tarball_gcc=$title_gcc.tar.bz2
tarball_gmp=$title_gmp.tar.lz
tarball_gpm=$title_gpm.tar.lzma
tarball_libffi=$title_libffi.tar.gz
tarball_linux=$title_linux.tar.xz
tarball_mingww64=$title_mingww64.tar.bz2
tarball_mpc=$title_mpc.tar.gz
tarball_mpfr=$title_mpfr.tar.xz
tarball_musl=$title_musl.tar.gz
tarball_ncurses=$title_ncurses.tar.gz
tarball_zlib=$title_zlib.tar.xz

my_fetch $tarball_binutils "http://ftpmirror.gnu.org/binutils/$tarball_binutils"
my_fetch $tarball_djbnu    "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/v2gnu/$tarball_djbnu"
my_fetch $tarball_djcrx    "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/$tarball_djcrx"
my_fetch $tarball_djgcc    "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2gnu/$tarball_djgcc"
my_fetch $tarball_djlsr    "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/$tarball_djlsr"
my_fetch $tarball_gcc      "http://ftpmirror.gnu.org/gcc/$title_gcc/$tarball_gcc"
my_fetch $tarball_gmp      "https://gmplib.org/download/gmp/$tarball_gmp"
my_fetch $tarball_gpm      "http://www.nico.schottelius.org/software/gpm/archives/$tarball_gpm"
my_fetch $tarball_libffi   "ftp://sourceware.org/pub/libffi/$tarball_libffi"
my_fetch $tarball_linux    "https://cdn.kernel.org/pub/linux/kernel/v4.x/$tarball_linux"
my_fetch $tarball_mingww64 "https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/$tarball_mingww64/download"
my_fetch $tarball_mpc      "ftp://ftp.gnu.org/gnu/mpc/$tarball_mpc"
my_fetch $tarball_mpfr     "http://www.mpfr.org/mpfr-current/$tarball_mpfr"
my_fetch $tarball_musl     "https://www.musl-libc.org/releases/$tarball_musl"
my_fetch $tarball_ncurses  "http://ftp.gnu.org/gnu/ncurses/$tarball_ncurses"
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
my_extract $title_gpm      $tarball_gpm
my_extract $title_libffi   $tarball_libffi
my_extract $title_linux    $tarball_linux
my_extract $title_mingww64 $tarball_mingww64
my_extract $title_mpc      $tarball_mpc
my_extract $title_mpfr     $tarball_mpfr
my_extract $title_musl     $tarball_musl
my_extract $title_ncurses  $tarball_ncurses
my_extract $title_zlib     $tarball_zlib

################################################################################

prefix_native="$PWD/native"
sysroot_linux_x86="$PWD/sysroot-linux-x86"
sysroot_linux_x86_64="$PWD/sysroot-linux-x86_64"
sysroot_win32="$PWD/sysroot-win32"
sysroot_win64="$PWD/sysroot-win64"
sysroot_dos="$PWD/sysroot-dos"
mkdir -p "$sysroot_linux_x86"   ; cd "$sysroot_linux_x86"   ; mkdir -p bin include lib usr/bin usr/include usr/lib; cd ..
mkdir -p "$sysroot_linux_x86_64"; cd "$sysroot_linux_x86_64"; mkdir -p bin include lib usr/bin usr/include usr/lib; cd ..
mkdir -p "$sysroot_win32"       ; cd "$sysroot_win32"       ; mkdir -p bin include lib; cd ..
mkdir -p "$sysroot_win64"       ; cd "$sysroot_win64"       ; mkdir -p bin include lib; cd ..
mkdir -p "$sysroot_dos"         ; cd "$sysroot_dos"         ; mkdir -p bin include lib; cd ..
if [ ! -e "$sysroot_win32/mingw" ]; then
	ln -s "$sysroot_win32" "$sysroot_win32/mingw"
fi
if [ ! -e "$sysroot_win64/mingw" ]; then
	ln -s "$sysroot_win64" "$sysroot_win64/mingw"
fi
if [ ! -e "$sysroot_dos/dev/env/DJDIR" ]; then
	mkdir -p "$sysroot_dos/dev/env"
	ln -s "$sysroot_dos" "$sysroot_dos/dev/env/DJDIR"
fi
if [ ! -e "$sysroot_dos"/sys-include ]; then
	ln -s "$sysroot_dos"/include "$sysroot_dos"/sys-include
fi

export PATH="$prefix_native/bin:$PATH"
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

	ncurses-*)
		patch -p1 < ../../ncurses-invoke-cpp-with-P.patch
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
maybe_do_patch $title_ncurses

################################################################################

do_build_autotools_native() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=$build_triplet \
		--prefix="$prefix_native" \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install
}

do_build_autotools_linux_x86() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=i686-pc-linux-musl \
		--prefix=/usr \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot_linux_x86"
}

do_build_autotools_linux_x86_64() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=x86_64-pc-linux-musl \
		--prefix=/usr \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot_linux_x86_64"
}

do_build_autotools_win32() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=i686-w64-mingw32 \
		--prefix= \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot_win32"
}

do_build_autotools_win64() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=x86_64-w64-mingw32 \
		--prefix= \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot_win64"
}

do_build_autotools_dos() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=i586-pc-msdosdjgpp \
		--prefix= \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot_dos"
}

gcc_conf_disables=" \
	--disable-bootstrap \
	--disable-decimal-float \
	--disable-libatomic \
	--disable-libgomp \
	--disable-libmpx \
	--disable-libmudflap \
	--disable-libquadmath \
	--disable-libsanitizer \
	--disable-libssp \
	--disable-lto \
	--disable-lto-plugin \
	--disable-multilib \
	--disable-nls \
	--disable-win32-registry \
"

ncurses_conf=" \
	--without-debug \
	--without-profile \
	--without-cxx \
	--without-cxx-binding \
	--without-ada \
	--without-manpages \
	--without-progs \
	--without-tests \
	--without-pkg-config \
	--disable-pc-files \
	--without-shared \
	--without-cxx-shared \
	--without-libtool \
	--with-termlib \
	--without-gpm \
	--without-dlsym \
	--without-sysmouse \
	--enable-termcap \
	--without-develop \
	--enable-const \
"

do_build() {
	local buildname="$1"

	case "$buildname" in

	$title_binutils-build-native-to-linux-x86)
		do_build_autotools_native $title_binutils \
			--target=i686-pc-linux-musl --with-sysroot="$sysroot_linux_x86" \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_binutils-build-native-to-linux-x86_64)
		do_build_autotools_native $title_binutils \
			--target=x86_64-pc-linux-musl --with-sysroot="$sysroot_linux_x86_64" \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_binutils-build-native-to-win32)
		do_build_autotools_native $title_binutils \
			--target=i686-w64-mingw32 --with-sysroot="$sysroot_win32" \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_binutils-build-native-to-win64)
		do_build_autotools_native $title_binutils \
			--target=x86_64-w64-mingw32 --with-sysroot="$sysroot_win64" \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_djbnu-build-native-to-dos)
		do_build_autotools_native $title_djbnu \
			--target=i586-pc-msdosdjgpp --with-sysroot="$sysroot_dos" \
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

	$title_linux-build-linux-x86-headers)
		cd ../$title_linux
		make O=../$title_linux-build-linux-x86-headers ARCH=i386 INSTALL_HDR_PATH="$sysroot_linux_x86"/usr defconfig headers_install
		cd ../$title_linux-build-linux-x86-headers
		;;

	$title_linux-build-linux-x86_64-headers)
		cd ../$title_linux
		make O=../$title_linux-build-linux-x86_64-headers ARCH=x86_64 INSTALL_HDR_PATH="$sysroot_linux_x86_64"/usr defconfig headers_install
		cd ../$title_linux-build-linux-x86_64-headers
		;;

	$title_mingww64-build-win32-headers)
		../$title_mingww64/mingw-w64-headers/configure \
			--build=$build_triplet --host=i686-w64-mingw32 \
			--prefix=
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_win32"
		;;

	$title_mingww64-build-win64-headers)
		../$title_mingww64/mingw-w64-headers/configure \
			--build=$build_triplet --host=x86_64-w64-mingw32 \
			--prefix=
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_win64"
		;;

	$title_djcrx-build-dos-headers)
		cp -R ../$title_djcrx/. .
		cp -R ../$title_djlsr/. .
		find . -type f -name "*.o" -or -name "*.a" | xargs rm
		cp -R include/. "$sysroot_dos"/include
		;;

	$title_musl-build-linux-x86)
		../$title_musl/configure \
			--build=$build_triplet --target=i686-pc-linux-musl \
			--prefix=/usr --enable-optimize --disable-shared --disable-wrapper
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linux_x86"
		;;

	$title_musl-build-linux-x86_64)
		../$title_musl/configure \
			--build=$build_triplet --target=x86_64-pc-linux-musl \
			--prefix=/usr --enable-optimize --disable-shared --disable-wrapper
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linux_x86_64"
		;;

	$title_mingww64-build-win32-crt)
		../$title_mingww64/mingw-w64-crt/configure \
			--build=$build_triplet --host=i686-w64-mingw32 \
			--prefix= \
			--enable-wildcard
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_win32"
		;;

	$title_mingww64-build-win64-crt)
		../$title_mingww64/mingw-w64-crt/configure \
			--build=$build_triplet --host=x86_64-w64-mingw32 \
			--prefix= \
			--enable-wildcard
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_win64"
		;;

	$title_djcrx-build-dos-crt)
		cp -R ../$title_djcrx/. .
		cp -R ../$title_djlsr/. .
		find . -type f -name "*.o" -or -name "*.a" | xargs rm
		cd src
		rm -f *.opt
		sed -i 's/-Werror//g' makefile.cfg
		# Build DJGPP libc without any target binaries, because the latter would
		# fail because we don't have full gcc yet (libgcc.a missing)
		# based on src/makefile's "all" target:
		make misc.exe config ../hostbin ../bin ../include ../info ../lib makemake.exe
		make -C djasm native
		make -C stub native
		make -C utils native
		make -C dxe native
		make -C mkdoc
		make -C libc
		#make -C debug
		#make -C djasm
		#make -C stub
		#make -C dxe
		#make -C libemu
		make -C libm
		#make -C utils
		#make -C docs
		make -f makempty
		make ../lib/libg.a ../lib/libpc.a
		cd ..
		cp lib/*.a lib/*.o "$sysroot_dos"/lib
		install -m 0755 hostbin/stubify.exe "$prefix_native"/bin/stubify
		install -m 0755 hostbin/stubedit.exe "$prefix_native"/bin/stubedit
		install -m 0755 hostbin/dxegen.exe "$prefix_native"/bin/dxegen
		;;

	$title_djcrx-build-dos-full)
		cp -R ../$title_djcrx/. .
		cp -R ../$title_djlsr/. .
		find . -type f -name "*.o" -or -name "*.a" | xargs rm
		cd src
		rm -f *.opt
		sed -i 's/-Werror//g' makefile.cfg
		make
		cd ..
		cp bin/*.exe "$sysroot_dos"/bin
		;;

	$title_gcc-build-native-to-linux-x86-gcc)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i686-pc-linux-musl \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_linux_x86" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c \
			$gcc_conf_disables
		make -j"$cpucount" all-gcc
		make -j"$cpucount" install-gcc
		;;

	$title_gcc-build-native-to-linux-x86_64-gcc)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=x86_64-pc-linux-musl \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_linux_x86_64" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c \
			$gcc_conf_disables
		make -j"$cpucount" all-gcc
		make -j"$cpucount" install-gcc
		;;

	$title_gcc-build-native-to-win32-gcc)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i686-w64-mingw32 \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_win32" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c \
			$gcc_conf_disables \
			--enable-threads=win32 --enable-sjlj-exceptions
		make -j"$cpucount" all-gcc
		make -j"$cpucount" install-gcc
		;;

	$title_gcc-build-native-to-win64-gcc)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=x86_64-w64-mingw32 \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_win64" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c \
			$gcc_conf_disables \
			--enable-threads=win32 --enable-sjlj-exceptions
		make -j"$cpucount" all-gcc
		make -j"$cpucount" install-gcc
		;;

	$title_djgcc-build-native-to-dos-gcc)
		../$title_djgcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i586-pc-msdosdjgpp \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_dos" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c \
			$gcc_conf_disables
		make -j"$cpucount" all-gcc
		make -j"$cpucount" install-gcc
		;;

	$title_gcc-build-native-to-linux-x86-full)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i686-pc-linux-musl \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_linux_x86" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c,c++ \
			$gcc_conf_disables
		make -j"$cpucount"
		make -j"$cpucount" install
		;;

	$title_gcc-build-native-to-linux-x86_64-full)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=x86_64-pc-linux-musl \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_linux_x86_64" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c,c++ \
			$gcc_conf_disables
		make -j"$cpucount"
		make -j"$cpucount" install
		;;

	$title_gcc-build-native-to-win32-full)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i686-w64-mingw32 \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_win32" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c,c++ \
			$gcc_conf_disables \
			--enable-threads=win32 --enable-sjlj-exceptions
		make -j"$cpucount"
		make -j"$cpucount" install
		;;

	$title_gcc-build-native-to-win64-full)
		../$title_gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=x86_64-w64-mingw32 \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_win64" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c,c++ \
			$gcc_conf_disables \
			--enable-threads=win32 --enable-sjlj-exceptions
		make -j"$cpucount"
		make -j"$cpucount" install
		;;

	$title_djgcc-build-native-to-dos-full)
		../$title_djgcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i586-pc-msdosdjgpp \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_dos" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c,c++ \
			$gcc_conf_disables
		make -j"$cpucount"
		make -j"$cpucount" install
		;;

	$title_gcc-build-win32-to-win32)
		do_build_autotools_win32 $title_gcc \
			--target=i686-w64-mingw32 \
			--with-local-prefix= \
			--with-build-sysroot="$sysroot_win32" \
			--with-gmp="$sysroot_win32" \
			--with-mpfr="$sysroot_win32" \
			--with-mpc="$sysroot_win32" \
			--enable-languages=c,c++ \
			$gcc_conf_disables \
			--enable-threads=win32 --enable-sjlj-exceptions
		;;

	$title_gcc-build-win64-to-win64)
		do_build_autotools_win64 $title_gcc \
			--target=x86_64-w64-mingw32 \
			--with-local-prefix= \
			--with-build-sysroot="$sysroot_win64" \
			--with-gmp="$sysroot_win64" \
			--with-mpfr="$sysroot_win64" \
			--with-mpc="$sysroot_win64" \
			--enable-languages=c,c++ \
			$gcc_conf_disables \
			--enable-threads=win32 --enable-sjlj-exceptions
		;;

	$title_djgcc-build-dos-to-dos)
		ac_cv_c_bigendian=no \
		do_build_autotools_dos $title_djgcc \
			--target=i586-pc-msdosdjgpp \
			--with-local-prefix= \
			--with-build-sysroot="$sysroot_dos" \
			--with-gmp="$sysroot_dos" \
			--with-mpfr="$sysroot_dos" \
			--with-mpc="$sysroot_dos" \
			--enable-languages=c,c++ \
			$gcc_conf_disables
		;;

	fbc-*-build-native)
		rm -f  "$prefix_native"/bin/fbc
		rm -rf "$prefix_native"/include/freebasic
		rm -rf "$prefix_native"/lib/freebasic
		rm -f config.mk
		echo 'ifeq ($(TARGET),i686-w64-mingw32)'                      >> config.mk
		echo "  CFLAGS += -I\"$sysroot_win32/lib/$title_libffi/include\"" >> config.mk
		echo 'endif'                                                  >> config.mk
		echo 'ifeq ($(TARGET),x86_64-w64-mingw32)'                    >> config.mk
		echo "  CFLAGS += -I\"$sysroot_win64/lib/$title_libffi/include\"" >> config.mk
		echo 'endif'                                                  >> config.mk
		echo "prefix := $prefix_native"                              >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile compiler install-compiler install-includes
		make -j"$cpucount" -f ../$title_fbc/makefile TARGET=i686-pc-linux-musl   rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../$title_fbc/makefile TARGET=x86_64-pc-linux-musl rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../$title_fbc/makefile TARGET=i686-w64-mingw32     rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../$title_fbc/makefile TARGET=x86_64-w64-mingw32   rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../$title_fbc/makefile TARGET=i586-pc-msdosdjgpp   rtlib gfxlib2 install-rtlib install-gfxlib2
		mv "$prefix_native"/lib/freebas/dos "$prefix_native"/lib/freebasic
		;;

	fbc-*-build-linux-x86)
		rm -f config.mk
		echo 'TARGET := i686-pc-linux-musl'                                 >> config.mk
		echo "CFLAGS += -I\"$sysroot_linux_x86/lib/$title_libffi/include\"" >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile all install DESTDIR="$sysroot_linux_x86"
		;;

	fbc-*-build-linux-x86_64)
		rm -f config.mk
		echo 'TARGET := x86_64-pc-linux-musl'                                  >> config.mk
		echo "CFLAGS += -I\"$sysroot_linux_x86_64/lib/$title_libffi/include\"" >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile all install DESTDIR="$sysroot_linux_x86_64"
		;;

	fbc-*-build-win32)
		rm -f  "$sysroot_win32"/bin/fbc.exe
		rm -rf "$sysroot_win32"/include/freebasic
		rm -rf "$sysroot_win32"/lib/freebasic
		rm -f config.mk
		echo 'TARGET := i686-w64-mingw32'                           >> config.mk
		echo "CFLAGS += -I\"$sysroot_win32/lib/$title_libffi/include\"" >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile all install DESTDIR="$sysroot_win32"
		;;

	fbc-*-build-win64)
		rm -f  "$sysroot_win64"/bin/fbc.exe
		rm -rf "$sysroot_win64"/include/freebasic
		rm -rf "$sysroot_win64"/lib/freebasic
		rm -f config.mk
		echo 'TARGET := x86_64-w64-mingw32'                         >> config.mk
		echo "CFLAGS += -I\"$sysroot_win64/lib/$title_libffi/include\"" >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile all install DESTDIR="$sysroot_win64"
		;;

	fbc-*-build-dos)
		rm -f  "$sysroot_dos"/bin/fbc.exe
		rm -rf "$sysroot_dos"/include/freebasic
		rm -rf "$sysroot_dos"/lib/freebasic
		rm -f config.mk
		echo 'TARGET := i586-pc-msdosdjgpp'                         >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile all install DESTDIR="$sysroot_dos"
		mv "$sysroot_dos"/lib/freebas/dos "$sysroot_dos"/lib/freebasic
		;;

	fbc-*-build-win32-standalone)
		rm -f config.mk
		echo 'TARGET := i686-w64-mingw32'                             >> config.mk
		echo "CFLAGS += -I\"$sysroot_win32/lib/$title_libffi/include\"" >> config.mk
		echo 'ENABLE_STANDALONE := 1'                                 >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile
		;;

	fbc-*-build-win64-standalone)
		rm -f config.mk
		echo 'TARGET := x86_64-w64-mingw32'                           >> config.mk
		echo "CFLAGS += -I\"$sysroot_win64/lib/$title_libffi/include\"" >> config.mk
		echo 'ENABLE_STANDALONE := 1'                                 >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile
		;;

	fbc-*-build-dos-standalone)
		rm -f config.mk
		echo 'TARGET := i586-pc-msdosdjgpp'                           >> config.mk
		echo 'ENABLE_STANDALONE := 1'                                 >> config.mk
		make -j"$cpucount" -f ../$title_fbc/makefile
		;;

	$title_gmp-build-native)  do_build_autotools_native $title_gmp;;
	$title_mpfr-build-native) do_build_autotools_native $title_mpfr --with-gmp="$prefix_native";;
	$title_mpc-build-native)  do_build_autotools_native $title_mpc  --with-gmp="$prefix_native" --with-mpfr="$prefix_native";;

	$title_libffi-build-linux-x86)    do_build_autotools_linux_x86    $title_libffi;;
	$title_libffi-build-linux-x86_64) do_build_autotools_linux_x86_64 $title_libffi;;

	$title_ncurses-build-linux-x86)
		do_build_autotools_linux_x86 $title_ncurses \
			--with-install-prefix="$sysroot_linux_x86" \
			$ncurses_conf
		;;

	$title_ncurses-build-linux-x86_64)
		do_build_autotools_linux_x86_64 $title_ncurses \
			--with-install-prefix="$sysroot_linux_x86_64" \
			$ncurses_conf
		;;

	$title_gpm-build-header)
		cp ../$title_gpm/src/headers/gpm.h "$sysroot_linux_x86"/usr/include
		cp ../$title_gpm/src/headers/gpm.h "$sysroot_linux_x86_64"/usr/include
		;;

	$title_gmp-build-win32)    do_build_autotools_win32 $title_gmp;;
	$title_mpfr-build-win32)   do_build_autotools_win32 $title_mpfr --with-gmp="$sysroot_win32";;
	$title_mpc-build-win32)    do_build_autotools_win32 $title_mpc  --with-gmp="$sysroot_win32" --with-mpfr="$sysroot_win32";;
	$title_libffi-build-win32) do_build_autotools_win32 $title_libffi;;

	$title_gmp-build-win64)    do_build_autotools_win64 $title_gmp;;
	$title_mpfr-build-win64)   do_build_autotools_win64 $title_mpfr --with-gmp="$sysroot_win64";;
	$title_mpc-build-win64)    do_build_autotools_win64 $title_mpc  --with-gmp="$sysroot_win64" --with-mpfr="$sysroot_win64";;
	$title_libffi-build-win64) do_build_autotools_win64 $title_libffi;;

	$title_gmp-build-dos)    do_build_autotools_dos $title_gmp;;
	$title_mpfr-build-dos)   do_build_autotools_dos $title_mpfr --with-gmp="$sysroot_dos";;
	$title_mpc-build-dos)    do_build_autotools_dos $title_mpc  --with-gmp="$sysroot_dos" --with-mpfr="$sysroot_dos";;

	$title_zlib-build-win32)
		cp -R ../$title_zlib/. .
		make -f win32/Makefile.gcc \
			libz.a install \
			PREFIX=i686-w64-mingw32- \
			BINARY_PATH=/bin \
			INCLUDE_PATH=/include \
			LIBRARY_PATH=/lib \
			DESTDIR="$sysroot_win32"
		;;

	$title_zlib-build-win64)
		cp -R ../$title_zlib/. .
		make -f win32/Makefile.gcc \
			libz.a install \
			PREFIX=x86_64-w64-mingw32- \
			BINARY_PATH=/bin \
			INCLUDE_PATH=/include \
			LIBRARY_PATH=/lib \
			DESTDIR="$sysroot_win64"
		;;

	$title_zlib-build-dos)
		cp -R ../$title_zlib/. .
		CHOST=i586-pc-msdosdjgpp ./configure --static --prefix=
		make
		make install DESTDIR="$sysroot_dos"
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
		remove_la_files_in_dirs "$prefix_native" "$sysroot_win32" "$sysroot_win64" "$sysroot_dos"
		cd ..
		touch "$buildname/build-done.stamp"
	fi
}

#
# gcc cross-toolchains + target libc
#

maybe_do_build $title_binutils-build-native-to-linux-x86
maybe_do_build $title_binutils-build-native-to-linux-x86_64
maybe_do_build $title_binutils-build-native-to-win32
maybe_do_build $title_binutils-build-native-to-win64
maybe_do_build $title_djbnu-build-native-to-dos

maybe_do_build $title_gmp-build-native
maybe_do_build $title_mpfr-build-native
maybe_do_build $title_mpc-build-native

maybe_do_build $title_mingww64-build-win32-headers
maybe_do_build $title_mingww64-build-win64-headers
maybe_do_build $title_djcrx-build-dos-headers

maybe_do_build $title_gcc-build-native-to-linux-x86-gcc
maybe_do_build $title_gcc-build-native-to-linux-x86_64-gcc
maybe_do_build $title_gcc-build-native-to-win32-gcc
maybe_do_build $title_gcc-build-native-to-win64-gcc
maybe_do_build $title_djgcc-build-native-to-dos-gcc

maybe_do_build $title_linux-build-linux-x86-headers
maybe_do_build $title_linux-build-linux-x86_64-headers
maybe_do_build $title_musl-build-linux-x86
maybe_do_build $title_musl-build-linux-x86_64
maybe_do_build $title_mingww64-build-win32-crt
maybe_do_build $title_mingww64-build-win64-crt
maybe_do_build $title_djcrx-build-dos-crt

maybe_do_build $title_gcc-build-native-to-linux-x86-full
maybe_do_build $title_gcc-build-native-to-linux-x86_64-full
maybe_do_build $title_gcc-build-native-to-win32-full
maybe_do_build $title_gcc-build-native-to-win64-full
maybe_do_build $title_djgcc-build-native-to-dos-full
maybe_do_build $title_djcrx-build-dos-full

#
# target libraries
#

maybe_do_build $title_libffi-build-linux-x86
maybe_do_build $title_libffi-build-linux-x86_64
maybe_do_build $title_libffi-build-win32
maybe_do_build $title_libffi-build-win64

maybe_do_build $title_ncurses-build-linux-x86
maybe_do_build $title_ncurses-build-linux-x86_64

maybe_do_build $title_gpm-build-header

maybe_do_build $title_gmp-build-win32
maybe_do_build $title_gmp-build-win64
maybe_do_build $title_gmp-build-dos

maybe_do_build $title_mpfr-build-win32
maybe_do_build $title_mpfr-build-win64
maybe_do_build $title_mpfr-build-dos

maybe_do_build $title_mpc-build-win32
maybe_do_build $title_mpc-build-win64
maybe_do_build $title_mpc-build-dos

maybe_do_build $title_zlib-build-win32
maybe_do_build $title_zlib-build-win64
maybe_do_build $title_zlib-build-dos

#
# fbc cross-compiler & target programs
#

maybe_do_build fbc-$version_fbc-build-native

maybe_do_build $title_binutils-build-win32-to-win32
maybe_do_build $title_binutils-build-win64-to-win64
maybe_do_build $title_djbnu-build-dos-to-dos

maybe_do_build $title_gcc-build-win32-to-win32
maybe_do_build $title_gcc-build-win64-to-win64
maybe_do_build $title_djgcc-build-dos-to-dos

maybe_do_build fbc-$version_fbc-build-linux-x86
maybe_do_build fbc-$version_fbc-build-linux-x86_64
maybe_do_build fbc-$version_fbc-build-win32
maybe_do_build fbc-$version_fbc-build-win64
maybe_do_build fbc-$version_fbc-build-dos
maybe_do_build fbc-$version_fbc-build-win32-standalone
maybe_do_build fbc-$version_fbc-build-win64-standalone
maybe_do_build fbc-$version_fbc-build-dos-standalone

echo "ok"
