#!/bin/bash
#
# Requirements:
#  wget, unzip, xz-utils, lzip
#  gcc, g++, bison, flex, texinfo (makeinfo), pkg-config
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

if [ ! -f ../downloads/config.sub ]; then
	wget -O ../downloads/config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
	chmod +x ../downloads/config.sub
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

# X11
fetch_extract inputproto       2.3.2  tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract kbproto          1.0.7  tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract libpthread-stubs 0.3    tar.bz2 "https://xcb.freedesktop.org/dist/%s"
fetch_extract libX11           1.6.3  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXau           1.0.8  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libxcb           1.12   tar.bz2 "https://xcb.freedesktop.org/dist/%s"
fetch_extract util-macros      1.19.0 tar.bz2 "https://www.x.org/releases/individual/util/%s"
fetch_extract xcb-proto        1.12   tar.bz2 "https://xcb.freedesktop.org/dist/%s"
fetch_extract xextproto        7.3.0  tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract xproto           7.0.31 tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract xtrans           1.3.5  tar.bz2 "https://www.x.org/releases/individual/lib/%s"

################################################################################

prefix_native="$PWD/native"
mkdir -p "$prefix_native"; cd "$prefix_native"; mkdir -p bin include lib; cd ..
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

	*proto|libpthread-stubs)
		cp ../../downloads/config.guess ../../downloads/config.sub .
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

maybe_do_patch       inputproto
maybe_do_patch          kbproto
maybe_do_patch        xextproto
maybe_do_patch           xproto
maybe_do_patch libpthread-stubs

################################################################################

sysroot_linmus32="$PWD/sysroot-linux-musl-x86"
sysroot_linmus64="$PWD/sysroot-linux-musl-x86_64"
sysroot_win32="$PWD/sysroot-win32"
sysroot_win64="$PWD/sysroot-win64"
sysroot_dos="$PWD/sysroot-dos"
mkdir -p "$sysroot_linmus32"; cd "$sysroot_linmus32"; mkdir -p bin include lib usr/bin usr/include usr/lib; cd ..
mkdir -p "$sysroot_linmus64"; cd "$sysroot_linmus64"; mkdir -p bin include lib usr/bin usr/include usr/lib; cd ..
mkdir -p "$sysroot_win32"   ; cd "$sysroot_win32"   ; mkdir -p bin include lib; cd ..
mkdir -p "$sysroot_win64"   ; cd "$sysroot_win64"   ; mkdir -p bin include lib; cd ..
mkdir -p "$sysroot_dos"     ; cd "$sysroot_dos"     ; mkdir -p bin include lib; cd ..
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

sed -e "s|@nativepath@|$PATH|g" -e "s|@targetsysroot@|$sysroot_linmus32|g" < ../patches/pkg-config-wrapper > "$prefix_native/bin/i686-pc-linux-musl-pkg-config"
sed -e "s|@nativepath@|$PATH|g" -e "s|@targetsysroot@|$sysroot_linmus64|g" < ../patches/pkg-config-wrapper > "$prefix_native/bin/x86_64-pc-linux-musl-pkg-config"
chmod +x "$prefix_native"/bin/*-pkg-config

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

do_build_autotools_linmus32() {
	local srcname="$1"
	shift
	PKG_CONFIG=i686-pc-linux-musl-pkg-config \
	../"$srcname"/configure \
		--build=$build_triplet --host=i686-pc-linux-musl \
		--prefix=/usr \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot_linmus32"
}

do_build_autotools_linmus64() {
	local srcname="$1"
	shift
	PKG_CONFIG=x86_64-pc-linux-musl-pkg-config \
	../"$srcname"/configure \
		--build=$build_triplet --host=x86_64-pc-linux-musl \
		--prefix=/usr \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot_linmus64"
}

do_build_autotools_win32() {
	local srcname="$1"
	shift
	PKG_CONFIG=i686-w64-mingw32-pkg-config \
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
	PKG_CONFIG=x86_64-w64-mingw32-pkg-config \
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
	PKG_CONFIG=i586-pc-msdosdjgpp-pkg-config \
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

	# Add cross tools to PATH for non-native builds. Ideally it could always be
	# in the PATH, but the "cross" compilers may overlap with the native tools,
	# without necessarily being ready for use (e.g. if build system is x86_64-pc-linux-gnu
	# and we have a native gcc/x86_64-pc-linux-gnu-gcc in $prefix_native/bin, but no glibc yet).
	export ORIG_PATH="$PATH"
	case "$buildname" in
	*-build-native*)
		;;
	*)
		export PATH="$prefix_native/bin:$PATH"
		;;
	esac

	case "$buildname" in

	binutils-build-native-to-linmus32) do_build_autotools_native binutils --target=i686-pc-linux-musl   --with-sysroot="$sysroot_linmus32" $binutils_conf;;
	binutils-build-native-to-linmus64) do_build_autotools_native binutils --target=x86_64-pc-linux-musl --with-sysroot="$sysroot_linmus64" $binutils_conf;;
	binutils-build-native-to-win32   ) do_build_autotools_native binutils --target=i686-w64-mingw32     --with-sysroot="$sysroot_win32"    $binutils_conf;;
	binutils-build-native-to-win64   ) do_build_autotools_native binutils --target=x86_64-w64-mingw32   --with-sysroot="$sysroot_win64"    $binutils_conf;;
	djbnu-build-native-to-dos        ) do_build_autotools_native djbnu    --target=i586-pc-msdosdjgpp   --with-sysroot="$sysroot_dos"      $binutils_conf;;
	binutils-build-win32-to-win32    ) do_build_autotools_win32  binutils --target=i686-w64-mingw32   $binutils_conf;;
	binutils-build-win64-to-win64    ) do_build_autotools_win64  binutils --target=x86_64-w64-mingw32 $binutils_conf;;
	djbnu-build-dos-to-dos           ) do_build_autotools_dos    djbnu    --target=i586-pc-msdosdjgpp $binutils_conf;;

	linux-build-linmus32-headers)
		cd ../linux
		make O=../linux-build-linmus32-headers ARCH=i386 CROSS_COMPILE=i686-pc-linux-musl- INSTALL_HDR_PATH="$sysroot_linmus32"/usr headers_install
		cd ../linux-build-linmus32-headers
		;;

	linux-build-linmus64-headers)
		cd ../linux
		make O=../linux-build-linmus64-headers ARCH=x86_64 CROSS_COMPILE=x86_64-pc-linux-musl- INSTALL_HDR_PATH="$sysroot_linmus64"/usr headers_install
		cd ../linux-build-linmus64-headers
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

	musl-build-linmus32)
		../musl/configure \
			--build=$build_triplet --target=i686-pc-linux-musl \
			--prefix=/usr --enable-optimize --disable-shared --disable-wrapper
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linmus32"
		;;

	musl-build-linmus64)
		../musl/configure \
			--build=$build_triplet --target=x86_64-pc-linux-musl \
			--prefix=/usr --enable-optimize --disable-shared --disable-wrapper
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linmus64"
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

	gcc-build-native-to-linmus32-gcc)
		../gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i686-pc-linux-musl \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_linmus32" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c \
			$gcc_conf_disables
		make -j"$cpucount" all-gcc
		make -j"$cpucount" install-gcc
		;;

	gcc-build-native-to-linmus64-gcc)
		../gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=x86_64-pc-linux-musl \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_linmus64" \
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

	gcc-build-native-to-linmus32-full)
		../gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i686-pc-linux-musl \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_linmus32" \
			--with-gmp="$prefix_native" \
			--with-mpfr="$prefix_native" \
			--with-mpc="$prefix_native" \
			--enable-static --disable-shared \
			--enable-languages=c,c++ \
			$gcc_conf_disables
		make -j"$cpucount"
		make -j"$cpucount" install
		;;

	gcc-build-native-to-linmus64-full)
		../gcc/configure \
			--build=$build_triplet --host=$build_triplet --target=x86_64-pc-linux-musl \
			--prefix="$prefix_native" \
			--with-sysroot="$sysroot_linmus64" \
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

	fbc-build-native)
		rm -f  "$prefix_native"/bin/fbc
		rm -rf "$prefix_native"/include/freebasic
		rm -rf "$prefix_native"/lib/freebasic
		echo "prefix := $prefix_native" > config.mk
		make -j"$cpucount" -f ../fbc/makefile compiler install-compiler install-includes
		make -j"$cpucount" -f ../fbc/makefile TARGET=i686-pc-linux-musl   rtlib         install-rtlib
		make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-pc-linux-musl rtlib         install-rtlib
		make -j"$cpucount" -f ../fbc/makefile TARGET=i686-w64-mingw32     rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-w64-mingw32   rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../fbc/makefile TARGET=i586-pc-msdosdjgpp   rtlib gfxlib2 install-rtlib install-gfxlib2
		mv "$prefix_native"/lib/freebas/dos "$prefix_native"/lib/freebasic
		;;

	fbc-build-win32-standalone) make -j"$cpucount" -f ../fbc/makefile TARGET=i686-w64-mingw32   ENABLE_STANDALONE=1;;
	fbc-build-win64-standalone) make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-w64-mingw32 ENABLE_STANDALONE=1;;
	fbc-build-dos-standalone  ) make -j"$cpucount" -f ../fbc/makefile TARGET=i586-pc-msdosdjgpp ENABLE_STANDALONE=1;;
	fbc-build-linmus32) make -j"$cpucount" -f ../fbc/makefile TARGET=i686-pc-linux-musl   DESTDIR="$sysroot_linmus32" prefix=/usr compiler rtlib install-compiler install-includes install-rtlib;;
	fbc-build-linmus64) make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-pc-linux-musl DESTDIR="$sysroot_linmus64" prefix=/usr compiler rtlib install-compiler install-includes install-rtlib;;
	fbc-build-win32   ) make -j"$cpucount" -f ../fbc/makefile TARGET=i686-w64-mingw32     DESTDIR="$sysroot_win32"    prefix=     all install;;
	fbc-build-win64   ) make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-w64-mingw32   DESTDIR="$sysroot_win64"    prefix=     all install;;
	fbc-build-dos     ) make -j"$cpucount" -f ../fbc/makefile TARGET=i586-pc-msdosdjgpp   DESTDIR="$sysroot_dos"      prefix=     all install
		mv "$sysroot_dos"/lib/freebas/dos "$sysroot_dos"/lib/freebasic
		;;

	mpfr-build-native) do_build_autotools_native mpfr --with-gmp="$prefix_native";;
	mpfr-build-win32 ) do_build_autotools_win32  mpfr --with-gmp="$sysroot_win32";;
	mpfr-build-win64 ) do_build_autotools_win64  mpfr --with-gmp="$sysroot_win64";;
	mpfr-build-dos   ) do_build_autotools_dos    mpfr --with-gmp="$sysroot_dos"  ;;

	mpc-build-native) do_build_autotools_native mpc --with-gmp="$prefix_native" --with-mpfr="$prefix_native";;
	mpc-build-win32 ) do_build_autotools_win32  mpc --with-gmp="$sysroot_win32" --with-mpfr="$sysroot_win32";;
	mpc-build-win64 ) do_build_autotools_win64  mpc --with-gmp="$sysroot_win64" --with-mpfr="$sysroot_win64";;
	mpc-build-dos   ) do_build_autotools_dos    mpc --with-gmp="$sysroot_dos"   --with-mpfr="$sysroot_dos"  ;;

	ncurses-build-linmus32) do_build_autotools_linmus32 ncurses --with-install-prefix="$sysroot_linmus32" $ncurses_conf;;
	ncurses-build-linmus64) do_build_autotools_linmus64 ncurses --with-install-prefix="$sysroot_linmus64" $ncurses_conf;;

	gpm-build-header)
		cp ../gpm/src/headers/gpm.h "$sysroot_linmus32"/usr/include
		cp ../gpm/src/headers/gpm.h "$sysroot_linmus64"/usr/include
		;;

	libffi-build-linmus32) do_build_autotools_linmus32 libffi; mv "$sysroot_linmus32"/usr/lib/libffi-*/include/* "$sysroot_linmus32"/usr/include;;
	libffi-build-linmus64) do_build_autotools_linmus64 libffi; mv "$sysroot_linmus64"/usr/lib/libffi-*/include/* "$sysroot_linmus64"/usr/include;;
	libffi-build-win32   ) do_build_autotools_win32    libffi; mv "$sysroot_win32"/lib/libffi-*/include/* "$sysroot_win32"/include;;
	libffi-build-win64   ) do_build_autotools_win64    libffi; mv "$sysroot_win64"/lib/libffi-*/include/* "$sysroot_win64"/include;;

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

	libX11-build-linmus32) do_build_autotools_linmus32 libX11 --disable-malloc0returnsnull;;
	libX11-build-linmus64) do_build_autotools_linmus64 libX11 --disable-malloc0returnsnull;;

	*proto-build-linmus32)
		PKG_CONFIG=i686-pc-linux-musl-pkg-config \
		../"${buildname%-build-linmus32}"/configure \
			--build=$build_triplet --host=i686-pc-linux-musl --prefix=/usr "$@"
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linmus32"
		;;

	*proto-build-linmus64)
		PKG_CONFIG=x86_64-pc-linux-musl-pkg-config \
		../"${buildname%-build-linmus64}"/configure \
			--build=$build_triplet --host=x86_64-pc-linux-musl --prefix=/usr "$@"
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linmus64"
		;;

	*-build-native  ) do_build_autotools_native   ${buildname%-build-native}  ;;
	*-build-linmus32) do_build_autotools_linmus32 ${buildname%-build-linmus32};;
	*-build-linmus64) do_build_autotools_linmus64 ${buildname%-build-linmus64};;
	*-build-win32   ) do_build_autotools_win32    ${buildname%-build-win32}   ;;
	*-build-win64   ) do_build_autotools_win64    ${buildname%-build-win64}   ;;
	*-build-dos     ) do_build_autotools_dos      ${buildname%-build-dos}     ;;

	*)
		echo "TODO: build $buildname"
		exit 1
		;;
	esac

	# Remove native tools (without target prefix) from $prefix_native/bin.
	# We build various "cross" compilers, and if one of them happens to match the
	# build system, it will install native tools too. This can cause problems for
	# following builds, e.g. if we have a "gcc" that doesn't fully work because
	# there is no glibc yet.
	case "$buildname" in
	gcc-*|binutils-*)
		(cd "$prefix_native"/bin/ && \
			rm -f \
				addr2line ar as c++filt cpp elfedit gcc gcc-ar gcc-nm gcc-ranlib gcov \
				gcov-tool gprof ld ld.bfd nm objcopy objdump ranlib readelf size strings strip)
		;;
	esac

	export PATH="$ORIG_PATH"
}

maybe_do_build() {
	buildname="$1"

	if [ ! -f "$buildname/build-done.stamp" ]; then
		echo "build: $buildname"
		rm -rf "$buildname"
		mkdir "$buildname"
		cd "$buildname"

		do_build "$buildname" > build-log.txt 2>&1

		# Remove libtool stuff, it's not needed. Otherwise we'd have to fix paths
		# in the *.la files to support cross-compilation with sysroot.
		remove_la_files_in_dirs \
			"$prefix_native" \
			"$sysroot_linmus32" \
			"$sysroot_linmus64" \
			"$sysroot_win32" \
			"$sysroot_win64" \
			"$sysroot_dos"

		# Leave .pc files. Some packages' build systems require pkg-config.
		# We rely on our pkg-config-wrapper to fix up the paths dynamically.

		cd ..
		touch "$buildname/build-done.stamp"
	fi
}

#
# gcc cross-toolchains + target libc
#

maybe_do_build binutils-build-native-to-linmus32
maybe_do_build binutils-build-native-to-linmus64
maybe_do_build binutils-build-native-to-win32
maybe_do_build binutils-build-native-to-win64
maybe_do_build djbnu-build-native-to-dos

maybe_do_build gmp-build-native
maybe_do_build mpfr-build-native
maybe_do_build mpc-build-native

maybe_do_build mingw-w64-build-win32-headers
maybe_do_build mingw-w64-build-win64-headers
maybe_do_build djcrx-build-dos-headers

maybe_do_build gcc-build-native-to-linmus32-gcc
maybe_do_build gcc-build-native-to-linmus64-gcc
maybe_do_build gcc-build-native-to-win32-gcc
maybe_do_build gcc-build-native-to-win64-gcc
maybe_do_build djgcc-build-native-to-dos-gcc

maybe_do_build linux-build-linmus32-headers
maybe_do_build linux-build-linmus64-headers
maybe_do_build musl-build-linmus32
maybe_do_build musl-build-linmus64
maybe_do_build mingw-w64-build-win32-crt
maybe_do_build mingw-w64-build-win64-crt
maybe_do_build djcrx-build-dos-crt

maybe_do_build gcc-build-native-to-linmus32-full
maybe_do_build gcc-build-native-to-linmus64-full
maybe_do_build gcc-build-native-to-win32-full
maybe_do_build gcc-build-native-to-win64-full
maybe_do_build djgcc-build-native-to-dos-full
maybe_do_build djcrx-build-dos-full

#
# target libraries
#

maybe_do_build libffi-build-linmus32
maybe_do_build libffi-build-linmus64
maybe_do_build libffi-build-win32
maybe_do_build libffi-build-win64

maybe_do_build ncurses-build-linmus32
maybe_do_build ncurses-build-linmus64
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

maybe_do_build       inputproto-build-linmus32
maybe_do_build          kbproto-build-linmus32
maybe_do_build        xcb-proto-build-linmus32
maybe_do_build        xextproto-build-linmus32
maybe_do_build           xproto-build-linmus32
maybe_do_build libpthread-stubs-build-linmus32
maybe_do_build      util-macros-build-linmus32
maybe_do_build           xtrans-build-linmus32

maybe_do_build       inputproto-build-linmus64
maybe_do_build          kbproto-build-linmus64
maybe_do_build        xcb-proto-build-linmus64
maybe_do_build        xextproto-build-linmus64
maybe_do_build           xproto-build-linmus64
maybe_do_build libpthread-stubs-build-linmus64
maybe_do_build      util-macros-build-linmus64
maybe_do_build           xtrans-build-linmus64

maybe_do_build libXau-build-linmus32
maybe_do_build libxcb-build-linmus32
maybe_do_build libX11-build-linmus32

maybe_do_build libXau-build-linmus64
maybe_do_build libxcb-build-linmus64
maybe_do_build libX11-build-linmus64

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

maybe_do_build fbc-build-linmus32
maybe_do_build fbc-build-linmus64
maybe_do_build fbc-build-win32
maybe_do_build fbc-build-win64
maybe_do_build fbc-build-dos
maybe_do_build fbc-build-win32-standalone
maybe_do_build fbc-build-win64-standalone
maybe_do_build fbc-build-dos-standalone

echo "ok"
