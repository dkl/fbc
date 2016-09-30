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

fetch_extract_custom fbc fbc-246172c59e6db0bb77811e10b70c2963237f2ee6 tar.gz "https://github.com/freebasic/fbc/archive/%s"
#fetch_extract_custom fbc FreeBASIC-1.05.0-source tar.xz "https://sourceforge.net/projects/fbc/files/Source%%20Code/%s/download"

if [ ! -f ../downloads/config.guess ]; then
	wget -O ../downloads/config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
	chmod +x ../downloads/config.guess
fi

# gcc toolchains
fetch_extract gmp       6.1.1  tar.lz   "https://gmplib.org/download/gmp/%s"
fetch_extract mpc       1.0.3  tar.gz   "ftp://ftp.gnu.org/gnu/mpc/%s"
fetch_extract mpfr      3.1.4  tar.xz   "http://www.mpfr.org/mpfr-current/%s"
fetch_extract binutils  2.27   tar.bz2  "http://ftpmirror.gnu.org/binutils/%s"
fetch_extract gcc       6.2.0  tar.bz2  "http://ftpmirror.gnu.org/gcc/gcc-6.2.0/%s"
fetch_extract linux     4.7.3  tar.xz   "https://cdn.kernel.org/pub/linux/kernel/v4.x/%s"
fetch_extract mingw-w64 v4.0.6 tar.bz2  "https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/%s/download"
fetch_extract musl      1.1.15 tar.gz   "https://www.musl-libc.org/releases/%s"
fetch_extract_custom djcrx djcrx205  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/%s"
fetch_extract_custom djlsr djlsr205  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/%s"
fetch_extract_custom djbnu bnu226sr3 zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/v2gnu/%s"
fetch_extract_custom djgcc gcc620s   zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2gnu/%s"

# FB dependencies
fetch_extract gpm     1.99.7 tar.lzma "http://www.nico.schottelius.org/software/gpm/archives/%s"
fetch_extract libffi  3.2.1  tar.gz   "ftp://sourceware.org/pub/libffi/%s"
fetch_extract zlib    1.2.8  tar.xz   "http://zlib.net/%s"
fetch_extract ncurses 6.0    tar.gz   "http://ftp.gnu.org/gnu/ncurses/%s"

################################################################################

prefix_native="$PWD/native"
export CFLAGS="-O2 -g0"
export CXXFLAGS="-O2 -g0"
cpucount="$(grep -c '^processor' /proc/cpuinfo)"
build_triplet=$(../downloads/config.guess)

################################################################################

do_patch() {
	srcdirname="$1"
	case "$srcdirname" in
	djbnu)
		cp -R gnu/binutils-*/. .
		rm -rf gnu manifest
		chmod +x configure
		;;

	djgcc)
		cp -R gnu/gcc-*/. .
		rm -rf gnu manifest
		chmod +x configure

		# Fix precheck for fixincludes
		patch -p1 < ../../patches/gcc-fixincludes-with-build-sysroot.patch

		# Disable fixincludes
		sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in
		;;

	gcc)
		# Fix precheck for fixincludes
		patch -p1 < ../../patches/gcc-fixincludes-with-build-sysroot.patch

		# Disable fixincludes
		sed -i 's@\./fixinc\.sh@-c true@' gcc/Makefile.in

		;;

	ncurses)
		patch -p1 < ../../patches/ncurses-invoke-cpp-with-P.patch
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

maybe_do_patch djbnu
maybe_do_patch djgcc
maybe_do_patch gcc
maybe_do_patch ncurses

################################################################################

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

binutils_conf="--disable-nls --disable-multilib --disable-werror"

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

	binutils-build-native-to-linux-x86   ) do_build_autotools_native binutils --target=i686-pc-linux-musl   --with-sysroot="$sysroot_linux_x86"    $binutils_conf;;
	binutils-build-native-to-linux-x86_64) do_build_autotools_native binutils --target=x86_64-pc-linux-musl --with-sysroot="$sysroot_linux_x86_64" $binutils_conf;;
	binutils-build-native-to-win32       ) do_build_autotools_native binutils --target=i686-w64-mingw32     --with-sysroot="$sysroot_win32"        $binutils_conf;;
	binutils-build-native-to-win64       ) do_build_autotools_native binutils --target=x86_64-w64-mingw32   --with-sysroot="$sysroot_win64"        $binutils_conf;;
	djbnu-build-native-to-dos            ) do_build_autotools_native djbnu    --target=i586-pc-msdosdjgpp   --with-sysroot="$sysroot_dos"          $binutils_conf;;
	binutils-build-win32-to-win32        ) do_build_autotools_win32  binutils --target=i686-w64-mingw32   $binutils_conf;;
	binutils-build-win64-to-win64        ) do_build_autotools_win64  binutils --target=x86_64-w64-mingw32 $binutils_conf;;
	djbnu-build-dos-to-dos               ) do_build_autotools_dos    djbnu    --target=i586-pc-msdosdjgpp $binutils_conf;;

	linux-build-linux-x86-headers)
		cd ../linux
		make O=../linux-build-linux-x86-headers ARCH=i386 INSTALL_HDR_PATH="$sysroot_linux_x86"/usr defconfig headers_install
		cd ../linux-build-linux-x86-headers
		;;

	linux-build-linux-x86_64-headers)
		cd ../linux
		make O=../linux-build-linux-x86_64-headers ARCH=x86_64 INSTALL_HDR_PATH="$sysroot_linux_x86_64"/usr defconfig headers_install
		cd ../linux-build-linux-x86_64-headers
		;;

	mingw-w64-build-win32-headers)
		../mingw-w64/mingw-w64-headers/configure \
			--build=$build_triplet --host=i686-w64-mingw32 \
			--prefix=
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_win32"
		;;

	mingw-w64-build-win64-headers)
		../mingw-w64/mingw-w64-headers/configure \
			--build=$build_triplet --host=x86_64-w64-mingw32 \
			--prefix=
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_win64"
		;;

	djcrx-build-dos-headers)
		cp -R ../djcrx/. .
		cp -R ../djlsr/. .
		find . -type f -name "*.o" -or -name "*.a" | xargs rm
		cp -R include/. "$sysroot_dos"/include
		;;

	musl-build-linux-x86)
		../musl/configure \
			--build=$build_triplet --target=i686-pc-linux-musl \
			--prefix=/usr --enable-optimize --disable-shared --disable-wrapper
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linux_x86"
		;;

	musl-build-linux-x86_64)
		../musl/configure \
			--build=$build_triplet --target=x86_64-pc-linux-musl \
			--prefix=/usr --enable-optimize --disable-shared --disable-wrapper
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linux_x86_64"
		;;

	mingw-w64-build-win32-crt)
		../mingw-w64/mingw-w64-crt/configure \
			--build=$build_triplet --host=i686-w64-mingw32 \
			--prefix= \
			--enable-wildcard
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_win32"
		;;

	mingw-w64-build-win64-crt)
		../mingw-w64/mingw-w64-crt/configure \
			--build=$build_triplet --host=x86_64-w64-mingw32 \
			--prefix= \
			--enable-wildcard
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_win64"
		;;

	djcrx-build-dos-crt)
		cp -R ../djcrx/. .
		cp -R ../djlsr/. .
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

	djcrx-build-dos-full)
		cp -R ../djcrx/. .
		cp -R ../djlsr/. .
		find . -type f -name "*.o" -or -name "*.a" | xargs rm
		cd src
		rm -f *.opt
		sed -i 's/-Werror//g' makefile.cfg
		make
		cd ..
		cp bin/*.exe "$sysroot_dos"/bin
		;;

	gcc-build-native-to-linux-x86-gcc)
		../gcc/configure \
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

	gcc-build-native-to-linux-x86_64-gcc)
		../gcc/configure \
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

	gcc-build-native-to-win32-gcc)
		../gcc/configure \
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

	gcc-build-native-to-win64-gcc)
		../gcc/configure \
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

	djgcc-build-native-to-dos-gcc)
		../djgcc/configure \
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

	gcc-build-native-to-linux-x86-full)
		../gcc/configure \
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

	gcc-build-native-to-linux-x86_64-full)
		../gcc/configure \
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

	gcc-build-native-to-win32-full)
		../gcc/configure \
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

	gcc-build-native-to-win64-full)
		../gcc/configure \
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

	djgcc-build-native-to-dos-full)
		../djgcc/configure \
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

	gcc-build-win32-to-win32)
		do_build_autotools_win32 gcc \
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

	gcc-build-win64-to-win64)
		do_build_autotools_win64 gcc \
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

	djgcc-build-dos-to-dos)
		ac_cv_c_bigendian=no \
		do_build_autotools_dos djgcc \
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
		echo "prefix := $prefix_native" > config.mk
		make -j"$cpucount" -f ../fbc/makefile compiler install-compiler install-includes
		make -j"$cpucount" -f ../fbc/makefile TARGET=i686-pc-linux-musl   rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-pc-linux-musl rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../fbc/makefile TARGET=i686-w64-mingw32     rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-w64-mingw32   rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../fbc/makefile TARGET=i586-pc-msdosdjgpp   rtlib gfxlib2 install-rtlib install-gfxlib2
		mv "$prefix_native"/lib/freebas/dos "$prefix_native"/lib/freebasic
		;;

	fbc-*-build-linux-x86)
		echo 'TARGET := i686-pc-linux-musl' > config.mk
		make -j"$cpucount" -f ../fbc/makefile all install DESTDIR="$sysroot_linux_x86"
		;;

	fbc-*-build-linux-x86_64)
		echo 'TARGET := x86_64-pc-linux-musl' > config.mk
		make -j"$cpucount" -f ../fbc/makefile all install DESTDIR="$sysroot_linux_x86_64"
		;;

	fbc-*-build-win32)
		echo 'TARGET := i686-w64-mingw32' > config.mk
		make -j"$cpucount" -f ../fbc/makefile all install DESTDIR="$sysroot_win32"
		;;

	fbc-*-build-win64)
		echo 'TARGET := x86_64-w64-mingw32' > config.mk
		make -j"$cpucount" -f ../fbc/makefile all install DESTDIR="$sysroot_win64"
		;;

	fbc-*-build-dos)
		echo 'TARGET := i586-pc-msdosdjgpp' > config.mk
		make -j"$cpucount" -f ../fbc/makefile all install DESTDIR="$sysroot_dos"
		mv "$sysroot_dos"/lib/freebas/dos "$sysroot_dos"/lib/freebasic
		;;

	fbc-*-build-win32-standalone)
		echo 'TARGET := i686-w64-mingw32' > config.mk
		echo 'ENABLE_STANDALONE := 1'    >> config.mk
		make -j"$cpucount" -f ../fbc/makefile
		;;

	fbc-*-build-win64-standalone)
		echo 'TARGET := x86_64-w64-mingw32' > config.mk
		echo 'ENABLE_STANDALONE := 1'      >> config.mk
		make -j"$cpucount" -f ../fbc/makefile
		;;

	fbc-*-build-dos-standalone)
		echo 'TARGET := i586-pc-msdosdjgpp' > config.mk
		echo 'ENABLE_STANDALONE := 1'      >> config.mk
		make -j"$cpucount" -f ../fbc/makefile
		;;

	mpfr-build-native) do_build_autotools_native mpfr --with-gmp="$prefix_native";;
	mpfr-build-win32 ) do_build_autotools_win32  mpfr --with-gmp="$sysroot_win32";;
	mpfr-build-win64 ) do_build_autotools_win64  mpfr --with-gmp="$sysroot_win64";;
	mpfr-build-dos   ) do_build_autotools_dos    mpfr --with-gmp="$sysroot_dos"  ;;

	mpc-build-native) do_build_autotools_native mpc --with-gmp="$prefix_native" --with-mpfr="$prefix_native";;
	mpc-build-win32 ) do_build_autotools_win32  mpc --with-gmp="$sysroot_win32" --with-mpfr="$sysroot_win32";;
	mpc-build-win64 ) do_build_autotools_win64  mpc --with-gmp="$sysroot_win64" --with-mpfr="$sysroot_win64";;
	mpc-build-dos   ) do_build_autotools_dos    mpc --with-gmp="$sysroot_dos"   --with-mpfr="$sysroot_dos"  ;;

	ncurses-build-linux-x86)    do_build_autotools_linux_x86    ncurses --with-install-prefix="$sysroot_linux_x86"    $ncurses_conf;;
	ncurses-build-linux-x86_64) do_build_autotools_linux_x86_64 ncurses --with-install-prefix="$sysroot_linux_x86_64" $ncurses_conf;;

	gpm-build-header)
		cp ../gpm/src/headers/gpm.h "$sysroot_linux_x86"/usr/include
		cp ../gpm/src/headers/gpm.h "$sysroot_linux_x86_64"/usr/include
		;;

	zlib-build-win32)
		cp -R ../zlib/. .
		make -f win32/Makefile.gcc \
			libz.a install \
			PREFIX=i686-w64-mingw32- \
			BINARY_PATH=/bin \
			INCLUDE_PATH=/include \
			LIBRARY_PATH=/lib \
			DESTDIR="$sysroot_win32"
		;;

	zlib-build-win64)
		cp -R ../zlib/. .
		make -f win32/Makefile.gcc \
			libz.a install \
			PREFIX=x86_64-w64-mingw32- \
			BINARY_PATH=/bin \
			INCLUDE_PATH=/include \
			LIBRARY_PATH=/lib \
			DESTDIR="$sysroot_win64"
		;;

	zlib-build-dos)
		cp -R ../zlib/. .
		CHOST=i586-pc-msdosdjgpp ./configure --static --prefix=
		make
		make install DESTDIR="$sysroot_dos"
		;;

	*-build-native      ) do_build_autotools_native       ${buildname%-build-native}      ;;
	*-build-linux-x86   ) do_build_autotools_linux_x86    ${buildname%-build-linux-x86}   ;;
	*-build-linux-x86_64) do_build_autotools_linux_x86_64 ${buildname%-build-linux-x86_64};;
	*-build-win32       ) do_build_autotools_win32        ${buildname%-build-win32}       ;;
	*-build-win64       ) do_build_autotools_win64        ${buildname%-build-win64}       ;;
	*-build-dos         ) do_build_autotools_dos          ${buildname%-build-dos}         ;;

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

maybe_do_build binutils-build-native-to-linux-x86
maybe_do_build binutils-build-native-to-linux-x86_64
maybe_do_build binutils-build-native-to-win32
maybe_do_build binutils-build-native-to-win64
maybe_do_build djbnu-build-native-to-dos

maybe_do_build gmp-build-native
maybe_do_build mpfr-build-native
maybe_do_build mpc-build-native

maybe_do_build mingw-w64-build-win32-headers
maybe_do_build mingw-w64-build-win64-headers
maybe_do_build djcrx-build-dos-headers

maybe_do_build gcc-build-native-to-linux-x86-gcc
maybe_do_build gcc-build-native-to-linux-x86_64-gcc
maybe_do_build gcc-build-native-to-win32-gcc
maybe_do_build gcc-build-native-to-win64-gcc
maybe_do_build djgcc-build-native-to-dos-gcc

maybe_do_build linux-build-linux-x86-headers
maybe_do_build linux-build-linux-x86_64-headers
maybe_do_build musl-build-linux-x86
maybe_do_build musl-build-linux-x86_64
maybe_do_build mingw-w64-build-win32-crt
maybe_do_build mingw-w64-build-win64-crt
maybe_do_build djcrx-build-dos-crt

maybe_do_build gcc-build-native-to-linux-x86-full
maybe_do_build gcc-build-native-to-linux-x86_64-full
maybe_do_build gcc-build-native-to-win32-full
maybe_do_build gcc-build-native-to-win64-full
maybe_do_build djgcc-build-native-to-dos-full
maybe_do_build djcrx-build-dos-full

#
# target libraries
#

maybe_do_build libffi-build-linux-x86
maybe_do_build libffi-build-linux-x86_64
maybe_do_build libffi-build-win32
maybe_do_build libffi-build-win64

maybe_do_build ncurses-build-linux-x86
maybe_do_build ncurses-build-linux-x86_64
maybe_do_build gpm-build-header

maybe_do_build gmp-build-win32
maybe_do_build gmp-build-win64
maybe_do_build gmp-build-dos

maybe_do_build mpfr-build-win32
maybe_do_build mpfr-build-win64
maybe_do_build mpfr-build-dos

maybe_do_build mpc-build-win32
maybe_do_build mpc-build-win64
maybe_do_build mpc-build-dos

maybe_do_build zlib-build-win32
maybe_do_build zlib-build-win64
maybe_do_build zlib-build-dos

#
# fbc cross-compiler & target programs
#

maybe_do_build fbc-build-native

maybe_do_build binutils-build-win32-to-win32
maybe_do_build binutils-build-win64-to-win64
maybe_do_build djbnu-build-dos-to-dos

maybe_do_build gcc-build-win32-to-win32
maybe_do_build gcc-build-win64-to-win64
maybe_do_build djgcc-build-dos-to-dos

maybe_do_build fbc-build-linux-x86
maybe_do_build fbc-build-linux-x86_64
maybe_do_build fbc-build-win32
maybe_do_build fbc-build-win64
maybe_do_build fbc-build-dos
maybe_do_build fbc-build-win32-standalone
maybe_do_build fbc-build-win64-standalone
maybe_do_build fbc-build-dos-standalone

echo "ok"
