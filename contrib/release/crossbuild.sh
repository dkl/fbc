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
fetch_extract binutils  2.27   tar.bz2  "http://ftpmirror.gnu.org/binutils/%s"
fetch_extract gcc       6.2.0  tar.bz2  "http://ftpmirror.gnu.org/gcc/gcc-6.2.0/%s"
fetch_extract glibc     2.24   tar.xz   "http://ftp.gnu.org/gnu/glibc/%s"
fetch_extract gmp       6.1.1  tar.lz   "https://gmplib.org/download/gmp/%s"
fetch_extract linux     4.7.3  tar.xz   "https://cdn.kernel.org/pub/linux/kernel/v4.x/%s"
fetch_extract mingw-w64 v4.0.6 tar.bz2  "https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/%s/download"
fetch_extract mpc       1.0.3  tar.gz   "ftp://ftp.gnu.org/gnu/mpc/%s"
fetch_extract mpfr      3.1.4  tar.xz   "http://www.mpfr.org/mpfr-current/%s"
fetch_extract musl      1.1.15 tar.gz   "https://www.musl-libc.org/releases/%s"
fetch_extract_custom djcrx djcrx205  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/%s"
fetch_extract_custom djlsr djlsr205  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/%s"
fetch_extract_custom djbnu bnu226sr3 zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/v2gnu/%s"
fetch_extract_custom djgcc gcc620s   zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2gnu/%s"

# FB rtlib dependencies
fetch_extract gpm     1.99.7 tar.lzma "http://www.nico.schottelius.org/software/gpm/archives/%s"
fetch_extract libffi  3.2.1  tar.gz   "ftp://sourceware.org/pub/libffi/%s"
fetch_extract zlib    1.2.8  tar.xz   "http://zlib.net/%s"
fetch_extract ncurses 6.0    tar.gz   "http://ftp.gnu.org/gnu/ncurses/%s"
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

prefix_native="$PWD/prefix-native"
prefix_cross_lingnu32="$PWD/prefix-cross-lingnu32"
prefix_cross_lingnu64="$PWD/prefix-cross-lingnu64"
prefix_cross_linmus32="$PWD/prefix-cross-linmus32"
prefix_cross_linmus64="$PWD/prefix-cross-linmus64"
prefix_cross_win32="$PWD/prefix-cross-win32"
prefix_cross_win64="$PWD/prefix-cross-win64"
prefix_cross_dos="$PWD/prefix-cross-dos"
mkdir -p "$prefix_native"        ; cd "$prefix_native"        ; mkdir -p bin include lib; cd ..
mkdir -p "$prefix_cross_lingnu32"; cd "$prefix_cross_lingnu32"; mkdir -p bin include lib; cd ..
mkdir -p "$prefix_cross_lingnu64"; cd "$prefix_cross_lingnu64"; mkdir -p bin include lib; cd ..
mkdir -p "$prefix_cross_linmus32"; cd "$prefix_cross_linmus32"; mkdir -p bin include lib; cd ..
mkdir -p "$prefix_cross_linmus64"; cd "$prefix_cross_linmus64"; mkdir -p bin include lib; cd ..
mkdir -p "$prefix_cross_win32"   ; cd "$prefix_cross_win32"   ; mkdir -p bin include lib; cd ..
mkdir -p "$prefix_cross_win64"   ; cd "$prefix_cross_win64"   ; mkdir -p bin include lib; cd ..
mkdir -p "$prefix_cross_dos"     ; cd "$prefix_cross_dos"     ; mkdir -p bin include lib; cd ..
export CFLAGS="-O2 -g0"
export CXXFLAGS="-O2 -g0"
cpucount="$(grep -c '^processor' /proc/cpuinfo)"
build_triplet=$(../downloads/config.guess)

prepend_path() {
  export PATH="$1:$PATH"
}

################################################################################

do_patch() {
	srcdirname="$1"
	case "$srcdirname" in
	djbnu)
		cp -R gnu/binutils-*/. .
		rm -rf gnu manifest
		chmod +x configure missing install-sh
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

sysroot_lingnu32="$PWD/sysroot-linux-gnu-x86"
sysroot_lingnu64="$PWD/sysroot-linux-gnu-x86_64"
sysroot_linmus32="$PWD/sysroot-linux-musl-x86"
sysroot_linmus64="$PWD/sysroot-linux-musl-x86_64"
sysroot_win32="$PWD/sysroot-win32"
sysroot_win64="$PWD/sysroot-win64"
sysroot_dos="$PWD/sysroot-dos"
mkdir -p "$sysroot_lingnu32"; cd "$sysroot_lingnu32"; mkdir -p bin lib usr/bin usr/include usr/lib; cd ..
mkdir -p "$sysroot_lingnu64"; cd "$sysroot_lingnu64"; mkdir -p bin lib usr/bin usr/include usr/lib; cd ..
mkdir -p "$sysroot_linmus32"; cd "$sysroot_linmus32"; mkdir -p bin lib usr/bin usr/include usr/lib; cd ..
mkdir -p "$sysroot_linmus64"; cd "$sysroot_linmus64"; mkdir -p bin lib usr/bin usr/include usr/lib; cd ..
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

sed -e "s|@nativepath@|$PATH|g" -e "s|@targetsysroot@|$sysroot_lingnu32|g" < ../patches/pkg-config-wrapper > "$prefix_cross_lingnu32/bin/i686-pc-linux-gnu-pkg-config"
sed -e "s|@nativepath@|$PATH|g" -e "s|@targetsysroot@|$sysroot_lingnu64|g" < ../patches/pkg-config-wrapper > "$prefix_cross_lingnu64/bin/x86_64-pc-linux-gnu-pkg-config"
sed -e "s|@nativepath@|$PATH|g" -e "s|@targetsysroot@|$sysroot_linmus32|g" < ../patches/pkg-config-wrapper > "$prefix_cross_linmus32/bin/i686-pc-linux-musl-pkg-config"
sed -e "s|@nativepath@|$PATH|g" -e "s|@targetsysroot@|$sysroot_linmus64|g" < ../patches/pkg-config-wrapper > "$prefix_cross_linmus64/bin/x86_64-pc-linux-musl-pkg-config"
chmod +x "$prefix_cross_lingnu32"/bin/*-pkg-config
chmod +x "$prefix_cross_lingnu64"/bin/*-pkg-config
chmod +x "$prefix_cross_linmus32"/bin/*-pkg-config
chmod +x "$prefix_cross_linmus64"/bin/*-pkg-config

################################################################################

do_build_autotools_native() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=$build_triplet \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install
}

do_build_autotools_lingnu32() {
	local srcname="$1"
	shift
	prepend_path "$prefix_cross_lingnu32"/bin
	PKG_CONFIG=i686-pc-linux-gnu-pkg-config \
	../"$srcname"/configure \
		--build=$build_triplet --host=i686-pc-linux-gnu \
		--prefix=/usr \
		--disable-static --enable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot_lingnu32"
}

do_build_autotools_lingnu64() {
	local srcname="$1"
	shift
	prepend_path "$prefix_cross_lingnu64"/bin
	PKG_CONFIG=x86_64-pc-linux-gnu-pkg-config \
	../"$srcname"/configure \
		--build=$build_triplet --host=x86_64-pc-linux-gnu \
		--prefix=/usr \
		--disable-static --enable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot_lingnu64"
}

do_build_autotools_linmus32() {
	local srcname="$1"
	shift
	prepend_path "$prefix_cross_linmus32"/bin
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
	prepend_path "$prefix_cross_linmus64"/bin
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
	prepend_path "$prefix_cross_win32"/bin
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
	prepend_path "$prefix_cross_win64"/bin
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
	prepend_path "$prefix_cross_dos"/bin
	PKG_CONFIG=i586-pc-msdosdjgpp-pkg-config \
	../"$srcname"/configure \
		--build=$build_triplet --host=i586-pc-msdosdjgpp \
		--prefix= \
		--enable-static --disable-shared "$@"
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot_dos"
}

# Remove native tools (without target prefix) from native bin dir.
# We build various "cross" compilers, and if one of them happens to match the
# build system, it will install native tools too. This can cause problems for
# following builds, e.g. if we have a "gcc" that doesn't fully work because
# there is no glibc yet.
remove_non_prefixed_cross_tools() {
	prefix="$1"
	(cd "$prefix"/bin/ && \
		rm -f \
			addr2line ar as c++ c++filt cpp elfedit g++ gcc gcc-ar gcc-nm gcc-ranlib gcov \
			gcov-tool gprof ld ld.bfd nm objcopy objdump ranlib readelf size strings strip)
}

binutils_conf="--disable-nls --disable-multilib --disable-werror"

gcc_conf=" \
	--disable-bootstrap \
	--disable-decimal-float \
	--disable-libatomic \
	--disable-libcilkrts \
	--disable-libffi \
	--disable-libgomp \
	--disable-libitm \
	--disable-libmpx \
	--disable-libmudflap \
	--disable-libquadmath \
	--disable-libsanitizer \
	--disable-libssp \
	--disable-libvtv \
	--disable-lto \
	--disable-lto-plugin \
	--disable-multilib \
	--disable-nls \
	--enable-languages=c,c++ \
"

gcc_conf_windows="--disable-win32-registry --enable-threads=win32 --enable-sjlj-exceptions"

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

gcc_glibc_bootstrap() {
	target="$1"
	linuxarch="$2"
	prefix="$3"
	sysroot="$4"

	mkdir gccbuild linuxbuild glibcbuild

	echo
	echo "gcc initial: gcc and g++, no libgcc or libstdc++"
	echo
	cd gccbuild
	../../gcc/configure \
		--build=$build_triplet --host=$build_triplet --target=$target \
		--with-gmp="$prefix_native" \
		--with-mpfr="$prefix_native" \
		--with-mpc="$prefix_native" \
		--enable-static --disable-shared \
		--prefix="$prefix" --with-sysroot="$sysroot" \
		$gcc_conf
	make -j"$cpucount" all-gcc
	make -j"$cpucount" install-gcc
	remove_non_prefixed_cross_tools "$prefix"
	remove_la_files_in_dirs "$prefix"
	cd ..

	prepend_path "$prefix"/bin

	echo
	echo "linux headers"
	echo
	workdir="$PWD"
	cd ../linux
	make O="$workdir"/linuxbuild ARCH=$linuxarch CROSS_COMPILE=$target- INSTALL_HDR_PATH="$sysroot"/usr headers_install
	cd "$workdir"

	echo
	echo "glibc initial: headers, crt1.o"
	echo
	cd glibcbuild
	BUILD_CC=gcc \
	../../glibc/configure --build=$build_triplet --host=$target \
		--enable-static --enable-shared \
		--prefix=/usr --enable-add-ons --enable-kernel=2.6.39 \
		--with-headers="$sysroot"/usr/include \
		libc_cv_ssp=no libc_cv_ssp_strong=no
	mkdir -p "$sysroot"/usr/include/gnu
	touch "$sysroot"/usr/include/gnu/stubs.h
	make install-headers DESTDIR="$sysroot"
	make csu/subdir_lib
	make csu/install-lib DESTDIR="$sysroot"
	cd ..

	echo
	echo "gcc: libgcc"
	echo
	cd gccbuild
	make -j"$cpucount" all-target-libgcc
	make -j"$cpucount" install-target-libgcc
	remove_la_files_in_dirs "$prefix"
	cd ..

	echo
	echo "glibc: libc"
	echo
	cd glibcbuild
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot"
	remove_la_files_in_dirs "$sysroot"
	cd ..

	echo
	echo "gcc: rest (libstdc++)"
	echo
	cd gccbuild
	make -j"$cpucount"
	make -j"$cpucount" install
	remove_non_prefixed_cross_tools "$prefix"
	remove_la_files_in_dirs "$prefix"
	cd ..
}

gcc_musl_bootstrap() {
	target="$1"
	linuxarch="$2"
	prefix="$3"
	sysroot="$4"

	mkdir gccbuild linuxbuild muslbuild

	echo
	echo "gcc initial: gcc and g++, no libgcc or libstdc++"
	echo
	cd gccbuild
	../../gcc/configure \
		--build=$build_triplet --host=$build_triplet --target=$target \
		--with-gmp="$prefix_native" \
		--with-mpfr="$prefix_native" \
		--with-mpc="$prefix_native" \
		--enable-static --disable-shared \
		--prefix="$prefix" --with-sysroot="$sysroot" \
		$gcc_conf
	make -j"$cpucount" all-gcc
	make -j"$cpucount" install-gcc
	remove_non_prefixed_cross_tools "$prefix"
	remove_la_files_in_dirs "$prefix"
	cd ..

	prepend_path "$prefix"/bin

	echo
	echo "linux headers"
	echo
	workdir="$PWD"
	cd ../linux
	make O="$workdir"/linuxbuild ARCH=$linuxarch CROSS_COMPILE=$target- INSTALL_HDR_PATH="$sysroot"/usr headers_install
	cd "$workdir"

	echo
	echo "musl libc"
	echo
	cd muslbuild
	../../musl/configure \
		--build=$build_triplet --target=$target \
		--prefix=/usr --enable-optimize --disable-shared --disable-wrapper
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot"
	remove_la_files_in_dirs "$sysroot"
	cd ..

	echo
	echo "gcc: rest (libgcc, libstdc++)"
	echo
	cd gccbuild
	make -j"$cpucount"
	make -j"$cpucount" install
	remove_non_prefixed_cross_tools "$prefix"
	remove_la_files_in_dirs "$prefix"
	cd ..
}

gcc_mingww64_bootstrap() {
	target="$1"
	prefix="$2"
	sysroot="$3"

	mkdir gccbuild headersbuild crtbuild

	echo
	echo "mingw-w64 headers"
	echo
	cd headersbuild
	../../mingw-w64/mingw-w64-headers/configure --build=$build_triplet --host=$target --prefix=
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot"
	cd ..

	echo
	echo "gcc initial: gcc and g++, no libgcc or libstdc++"
	echo
	cd gccbuild
	../../gcc/configure \
		--build=$build_triplet --host=$build_triplet --target=$target \
		--with-gmp="$prefix_native" \
		--with-mpfr="$prefix_native" \
		--with-mpc="$prefix_native" \
		--enable-static --disable-shared \
		--prefix="$prefix" --with-sysroot="$sysroot" \
		$gcc_conf $gcc_conf_windows
	make -j"$cpucount" all-gcc
	make -j"$cpucount" install-gcc
	remove_non_prefixed_cross_tools "$prefix"
	remove_la_files_in_dirs "$prefix"
	cd ..

	prepend_path "$prefix"/bin

	echo
	echo "mingw-w64 crt"
	echo
	cd crtbuild
	../../mingw-w64/mingw-w64-crt/configure --build=$build_triplet --host=$target --prefix= --enable-wildcard
	make -j"$cpucount"
	make -j"$cpucount" install DESTDIR="$sysroot"
	remove_la_files_in_dirs "$sysroot"
	cd ..

	echo
	echo "gcc: rest (libgcc, libstdc++)"
	echo
	cd gccbuild
	make -j"$cpucount"
	make -j"$cpucount" install
	remove_non_prefixed_cross_tools "$prefix"
	remove_la_files_in_dirs "$prefix"
	cd ..
}

gcc_djgpp_bootstrap() {
	mkdir gccbuild headersbuild crtbuild

	echo
	echo "DJGPP headers"
	echo
	cd headersbuild
	cp -R ../../djcrx/. .
	cp -R ../../djlsr/. .
	find . -type f -name "*.o" -or -name "*.a" | xargs rm
	cp -R include/. "$sysroot_dos"/include
	cd ..

	echo
	echo "gcc initial: gcc, g++, libgcc"
	echo
	cd gccbuild
	../../djgcc/configure \
		--build=$build_triplet --host=$build_triplet --target=i586-pc-msdosdjgpp \
		--with-gmp="$prefix_native" \
		--with-mpfr="$prefix_native" \
		--with-mpc="$prefix_native" \
		--enable-static --disable-shared \
		--prefix="$prefix_cross_dos" --with-sysroot="$sysroot_dos" \
		$gcc_conf
	make -j"$cpucount" all-gcc all-target-libgcc
	make -j"$cpucount" install-gcc install-target-libgcc
	remove_non_prefixed_cross_tools "$prefix_cross_dos"
	remove_la_files_in_dirs "$prefix_cross_dos"
	cd ..

	prepend_path "$prefix_cross_dos"/bin

	echo
	echo "DJGPP CRT"
	echo
	cd crtbuild
	cp -R ../../djcrx/. .
	cp -R ../../djlsr/. .
	find . -type f -name "*.o" -or -name "*.a" | xargs rm
	cd src
	rm -f *.opt
	sed -i 's/-Werror//g' makefile.cfg
	make
	cd ..
	cp lib/*.a lib/*.o "$sysroot_dos"/lib
	install -m 0755 hostbin/stubify.exe  "$prefix_cross_dos"/bin/stubify
	install -m 0755 hostbin/stubedit.exe "$prefix_cross_dos"/bin/stubedit
	install -m 0755 hostbin/dxegen.exe   "$prefix_cross_dos"/bin/dxegen
	cp bin/*.exe "$sysroot_dos"/bin
	cd ..

	echo
	echo "gcc: rest (libstdc++)"
	echo
	cd gccbuild
	make -j"$cpucount"
	make -j"$cpucount" install
	remove_non_prefixed_cross_tools "$prefix_cross_dos"
	remove_la_files_in_dirs "$prefix_cross_dos"
	cd ..
}

do_build() {
	local buildname="$1"

	ORIG_PATH="$PATH"

	case "$buildname" in

	binutils-build-native-to-lingnu32) do_build_autotools_native binutils --target=i686-pc-linux-gnu    --program-prefix=i686-pc-linux-gnu-    --prefix="$prefix_cross_lingnu32" --with-sysroot="$sysroot_lingnu32" $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-build-native-to-lingnu64) do_build_autotools_native binutils --target=x86_64-pc-linux-gnu  --program-prefix=x86_64-pc-linux-gnu-  --prefix="$prefix_cross_lingnu64" --with-sysroot="$sysroot_lingnu64" $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-build-native-to-linmus32) do_build_autotools_native binutils --target=i686-pc-linux-musl   --program-prefix=i686-pc-linux-musl-   --prefix="$prefix_cross_linmus32" --with-sysroot="$sysroot_linmus32" $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-build-native-to-linmus64) do_build_autotools_native binutils --target=x86_64-pc-linux-musl --program-prefix=x86_64-pc-linux-musl- --prefix="$prefix_cross_linmus64" --with-sysroot="$sysroot_linmus64" $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-build-native-to-win32   ) do_build_autotools_native binutils --target=i686-w64-mingw32     --program-prefix=i686-w64-mingw32-     --prefix="$prefix_cross_win32"    --with-sysroot="$sysroot_win32"    $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-build-native-to-win64   ) do_build_autotools_native binutils --target=x86_64-w64-mingw32   --program-prefix=x86_64-w64-mingw32-   --prefix="$prefix_cross_win64"    --with-sysroot="$sysroot_win64"    $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-build-win32-to-win32    ) do_build_autotools_win32  binutils --target=i686-w64-mingw32   $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-build-win64-to-win64    ) do_build_autotools_win64  binutils --target=x86_64-w64-mingw32 $binutils_conf; remove_non_prefixed_cross_tools;;

	djbnu-build-native-to-dos)
		../djbnu/configure \
			--build=$build_triplet --host=$build_triplet \
			--enable-static --disable-shared \
			--target=i586-pc-msdosdjgpp --program-prefix=i586-pc-msdosdjgpp- \
			--prefix="$prefix_cross_dos" --with-sysroot="$sysroot_dos" \
			$binutils_conf
		make configure-bfd
		cd bfd
		make stmp-lcoff-h
		cd ..
		make -j"$cpucount"
		make -j"$cpucount" install
		remove_non_prefixed_cross_tools
		;;

	djbnu-build-dos-to-dos           ) do_build_autotools_dos    djbnu    --target=i586-pc-msdosdjgpp $binutils_conf; remove_non_prefixed_cross_tools;;

	gcc-glibc-bootstrap-native-to-lingnu32) gcc_glibc_bootstrap i686-pc-linux-gnu    i386   "$prefix_cross_lingnu32" "$sysroot_lingnu32";;
	gcc-glibc-bootstrap-native-to-lingnu64) gcc_glibc_bootstrap x86_64-pc-linux-gnu  x86_64 "$prefix_cross_lingnu64" "$sysroot_lingnu64";;
	gcc-musl-bootstrap-native-to-linmus32)  gcc_musl_bootstrap  i686-pc-linux-musl   i386   "$prefix_cross_linmus32" "$sysroot_linmus32";;
	gcc-musl-bootstrap-native-to-linmus64)  gcc_musl_bootstrap  x86_64-pc-linux-musl x86_64 "$prefix_cross_linmus64" "$sysroot_linmus64";;
	gcc-mingw-w64-bootstrap-native-to-win32) gcc_mingww64_bootstrap i686-w64-mingw32   "$prefix_cross_win32" "$sysroot_win32";;
	gcc-mingw-w64-bootstrap-native-to-win64) gcc_mingww64_bootstrap x86_64-w64-mingw32 "$prefix_cross_win64" "$sysroot_win64";;
	gcc-djgpp-bootstrap-native-to-dos) gcc_djgpp_bootstrap;;

	gcc-build-win32-to-win32)
		do_build_autotools_win32 gcc \
			--target=i686-w64-mingw32 \
			--with-local-prefix= \
			--with-build-sysroot="$sysroot_win32" \
			--with-gmp="$sysroot_win32" \
			--with-mpfr="$sysroot_win32" \
			--with-mpc="$sysroot_win32" \
			$gcc_conf $gcc_conf_windows
		;;

	gcc-build-win64-to-win64)
		do_build_autotools_win64 gcc \
			--target=x86_64-w64-mingw32 \
			--with-local-prefix= \
			--with-build-sysroot="$sysroot_win64" \
			--with-gmp="$sysroot_win64" \
			--with-mpfr="$sysroot_win64" \
			--with-mpc="$sysroot_win64" \
			$gcc_conf $gcc_conf_windows
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
			$gcc_conf
		;;

	fbc-build-native)
		rm -f  "$prefix_native"/bin/fbc
		rm -rf "$prefix_native"/include/freebasic
		rm -rf "$prefix_native"/lib/freebasic
		echo "prefix := $prefix_native" > config.mk
		make -j"$cpucount" -f ../fbc/makefile compiler install-compiler install-includes
		prepend_path "$prefix_cross_linmus32"/bin
		prepend_path "$prefix_cross_linmus64"/bin
		prepend_path "$prefix_cross_win32"/bin
		prepend_path "$prefix_cross_win64"/bin
		prepend_path "$prefix_cross_dos"/bin
		make -j"$cpucount" -f ../fbc/makefile TARGET=i686-pc-linux-musl   rtlib         install-rtlib
		make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-pc-linux-musl rtlib         install-rtlib
		make -j"$cpucount" -f ../fbc/makefile TARGET=i686-w64-mingw32     rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-w64-mingw32   rtlib gfxlib2 install-rtlib install-gfxlib2
		make -j"$cpucount" -f ../fbc/makefile TARGET=i586-pc-msdosdjgpp   rtlib gfxlib2 install-rtlib install-gfxlib2
		mv "$prefix_native"/lib/freebas/dos "$prefix_native"/lib/freebasic
		rmdir "$prefix_native"/lib/freebas
		;;

	fbc-build-win32-standalone) prepend_path "$prefix_native"/bin; prepend_path "$prefix_cross_win32"/bin; make -j"$cpucount" -f ../fbc/makefile TARGET=i686-w64-mingw32   ENABLE_STANDALONE=1;;
	fbc-build-win64-standalone) prepend_path "$prefix_native"/bin; prepend_path "$prefix_cross_win64"/bin; make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-w64-mingw32 ENABLE_STANDALONE=1;;
	fbc-build-dos-standalone  ) prepend_path "$prefix_native"/bin; prepend_path "$prefix_cross_dos"/bin  ; make -j"$cpucount" -f ../fbc/makefile TARGET=i586-pc-msdosdjgpp ENABLE_STANDALONE=1;;
	fbc-build-lingnu32) prepend_path "$prefix_native"/bin; prepend_path "$prefix_cross_lingnu32"/bin; make -j"$cpucount" -f ../fbc/makefile TARGET=i686-pc-linux-gnu    DESTDIR="$sysroot_lingnu32" prefix=/usr compiler rtlib install-compiler install-includes install-rtlib;;
	fbc-build-lingnu64) prepend_path "$prefix_native"/bin; prepend_path "$prefix_cross_lingnu64"/bin; make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-pc-linux-gnu  DESTDIR="$sysroot_lingnu64" prefix=/usr compiler rtlib install-compiler install-includes install-rtlib;;
	fbc-build-linmus32) prepend_path "$prefix_native"/bin; prepend_path "$prefix_cross_linmus32"/bin; make -j"$cpucount" -f ../fbc/makefile TARGET=i686-pc-linux-musl   DESTDIR="$sysroot_linmus32" prefix=/usr compiler rtlib install-compiler install-includes install-rtlib;;
	fbc-build-linmus64) prepend_path "$prefix_native"/bin; prepend_path "$prefix_cross_linmus64"/bin; make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-pc-linux-musl DESTDIR="$sysroot_linmus64" prefix=/usr compiler rtlib install-compiler install-includes install-rtlib;;
	fbc-build-win32   ) prepend_path "$prefix_native"/bin; prepend_path "$prefix_cross_win32"/bin   ; make -j"$cpucount" -f ../fbc/makefile TARGET=i686-w64-mingw32     DESTDIR="$sysroot_win32"    prefix=     all install;;
	fbc-build-win64   ) prepend_path "$prefix_native"/bin; prepend_path "$prefix_cross_win64"/bin   ; make -j"$cpucount" -f ../fbc/makefile TARGET=x86_64-w64-mingw32   DESTDIR="$sysroot_win64"    prefix=     all install;;
	fbc-build-dos     ) prepend_path "$prefix_native"/bin; prepend_path "$prefix_cross_dos"/bin     ; make -j"$cpucount" -f ../fbc/makefile TARGET=i586-pc-msdosdjgpp   DESTDIR="$sysroot_dos"      prefix=     all install
		mv "$sysroot_dos"/lib/freebas/dos "$sysroot_dos"/lib/freebasic
		rmdir "$sysroot_dos"/lib/freebas
		;;

	mpfr-build-native) do_build_autotools_native mpfr --with-gmp="$prefix_native" --prefix="$prefix_native";;
	mpfr-build-win32 ) do_build_autotools_win32  mpfr --with-gmp="$sysroot_win32";;
	mpfr-build-win64 ) do_build_autotools_win64  mpfr --with-gmp="$sysroot_win64";;
	mpfr-build-dos   ) do_build_autotools_dos    mpfr --with-gmp="$sysroot_dos"  ;;

	mpc-build-native) do_build_autotools_native mpc --with-gmp="$prefix_native" --with-mpfr="$prefix_native" --prefix="$prefix_native";;
	mpc-build-win32 ) do_build_autotools_win32  mpc --with-gmp="$sysroot_win32" --with-mpfr="$sysroot_win32";;
	mpc-build-win64 ) do_build_autotools_win64  mpc --with-gmp="$sysroot_win64" --with-mpfr="$sysroot_win64";;
	mpc-build-dos   ) do_build_autotools_dos    mpc --with-gmp="$sysroot_dos"   --with-mpfr="$sysroot_dos"  ;;

	ncurses-build-lingnu32) do_build_autotools_lingnu32 ncurses --with-install-prefix="$sysroot_lingnu32" $ncurses_conf;;
	ncurses-build-lingnu64) do_build_autotools_lingnu64 ncurses --with-install-prefix="$sysroot_lingnu64" $ncurses_conf;;
	ncurses-build-linmus32) do_build_autotools_linmus32 ncurses --with-install-prefix="$sysroot_linmus32" $ncurses_conf;;
	ncurses-build-linmus64) do_build_autotools_linmus64 ncurses --with-install-prefix="$sysroot_linmus64" $ncurses_conf;;

	gpm-build-header)
		cp ../gpm/src/headers/gpm.h "$sysroot_lingnu32"/usr/include
		cp ../gpm/src/headers/gpm.h "$sysroot_lingnu64"/usr/include
		cp ../gpm/src/headers/gpm.h "$sysroot_linmus32"/usr/include
		cp ../gpm/src/headers/gpm.h "$sysroot_linmus64"/usr/include
		;;

	libffi-build-lingnu32) do_build_autotools_lingnu32 libffi; mv "$sysroot_lingnu32"/usr/lib/libffi-*/include/* "$sysroot_lingnu32"/usr/include;;
	libffi-build-lingnu64) do_build_autotools_lingnu64 libffi; mv "$sysroot_lingnu64"/usr/lib/libffi-*/include/* "$sysroot_lingnu64"/usr/include;;
	libffi-build-linmus32) do_build_autotools_linmus32 libffi; mv "$sysroot_linmus32"/usr/lib/libffi-*/include/* "$sysroot_linmus32"/usr/include;;
	libffi-build-linmus64) do_build_autotools_linmus64 libffi; mv "$sysroot_linmus64"/usr/lib/libffi-*/include/* "$sysroot_linmus64"/usr/include;;
	libffi-build-win32   ) do_build_autotools_win32    libffi; mv "$sysroot_win32"/lib/libffi-*/include/* "$sysroot_win32"/include;;
	libffi-build-win64   ) do_build_autotools_win64    libffi; mv "$sysroot_win64"/lib/libffi-*/include/* "$sysroot_win64"/include;;

	zlib-build-win32)
		prepend_path "$prefix_cross_win32"/bin
		cp -R ../zlib/. .
		make -f win32/Makefile.gcc libz.a install \
			PREFIX=i686-w64-mingw32- \
			BINARY_PATH=/bin INCLUDE_PATH=/include LIBRARY_PATH=/lib DESTDIR="$sysroot_win32"
		;;

	zlib-build-win64)
		prepend_path "$prefix_cross_win64"/bin
		cp -R ../zlib/. .
		make -f win32/Makefile.gcc libz.a install \
			PREFIX=x86_64-w64-mingw32- \
			BINARY_PATH=/bin INCLUDE_PATH=/include LIBRARY_PATH=/lib DESTDIR="$sysroot_win64"
		;;

	zlib-build-dos)
		prepend_path "$prefix_cross_dos"/bin
		cp -R ../zlib/. .
		CHOST=i586-pc-msdosdjgpp ./configure --static --prefix=
		make
		make install DESTDIR="$sysroot_dos"
		;;

	libX11-build-lingnu32) do_build_autotools_lingnu32 libX11 --disable-malloc0returnsnull;;
	libX11-build-lingnu64) do_build_autotools_lingnu64 libX11 --disable-malloc0returnsnull;;
	libX11-build-linmus32) do_build_autotools_linmus32 libX11 --disable-malloc0returnsnull;;
	libX11-build-linmus64) do_build_autotools_linmus64 libX11 --disable-malloc0returnsnull;;

	*proto-build-lingnu32)
		prepend_path "$prefix_cross_lingnu32"/bin
		PKG_CONFIG=i686-pc-linux-gnu-pkg-config \
		../"${buildname%-build-lingnu32}"/configure \
			--build=$build_triplet --host=i686-pc-linux-gnu --prefix=/usr "$@"
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_lingnu32"
		;;

	*proto-build-lingnu64)
		prepend_path "$prefix_cross_lingnu64"/bin
		PKG_CONFIG=x86_64-pc-linux-gnu-pkg-config \
		../"${buildname%-build-lingnu64}"/configure \
			--build=$build_triplet --host=x86_64-pc-linux-gnu --prefix=/usr "$@"
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_lingnu64"
		;;

	*proto-build-linmus32)
		prepend_path "$prefix_cross_linmus32"/bin
		PKG_CONFIG=i686-pc-linux-musl-pkg-config \
		../"${buildname%-build-linmus32}"/configure \
			--build=$build_triplet --host=i686-pc-linux-musl --prefix=/usr "$@"
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linmus32"
		;;

	*proto-build-linmus64)
		prepend_path "$prefix_cross_linmus64"/bin
		PKG_CONFIG=x86_64-pc-linux-musl-pkg-config \
		../"${buildname%-build-linmus64}"/configure \
			--build=$build_triplet --host=x86_64-pc-linux-musl --prefix=/usr "$@"
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linmus64"
		;;

	gmp-build-lingnu32) export CC_FOR_BUILD="gcc" CPP_FOR_BUILD="cpp"; do_build_autotools_lingnu32 gmp;;
	gmp-build-lingnu64) export CC_FOR_BUILD="gcc" CPP_FOR_BUILD="cpp"; do_build_autotools_lingnu64 gmp;;
	gmp-build-linmus32) export CC_FOR_BUILD="gcc" CPP_FOR_BUILD="cpp"; do_build_autotools_linmus32 gmp;;
	gmp-build-linmus64) export CC_FOR_BUILD="gcc" CPP_FOR_BUILD="cpp"; do_build_autotools_linmus64 gmp;;
	gmp-build-win32   ) export CC_FOR_BUILD="gcc" CPP_FOR_BUILD="cpp"; do_build_autotools_win32    gmp;;
	gmp-build-win64   ) export CC_FOR_BUILD="gcc" CPP_FOR_BUILD="cpp"; do_build_autotools_win64    gmp;;
	gmp-build-dos     ) export CC_FOR_BUILD="gcc" CPP_FOR_BUILD="cpp"; do_build_autotools_dos      gmp;;

	*-build-native  ) do_build_autotools_native   ${buildname%-build-native}  --prefix="$prefix_native";;
	*-build-lingnu32) do_build_autotools_lingnu32 ${buildname%-build-lingnu32};;
	*-build-lingnu64) do_build_autotools_lingnu64 ${buildname%-build-lingnu64};;
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
			"$prefix_cross_lingnu32" \
			"$prefix_cross_lingnu64" \
			"$prefix_cross_linmus32" \
			"$prefix_cross_linmus64" \
			"$prefix_cross_win32" \
			"$prefix_cross_win64" \
			"$prefix_cross_dos" \
			"$sysroot_lingnu32" \
			"$sysroot_lingnu64" \
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

maybe_do_build gmp-build-native
maybe_do_build mpfr-build-native
maybe_do_build mpc-build-native

maybe_do_build binutils-build-native-to-lingnu32
maybe_do_build binutils-build-native-to-lingnu64
maybe_do_build binutils-build-native-to-linmus32
maybe_do_build binutils-build-native-to-linmus64
maybe_do_build binutils-build-native-to-win32
maybe_do_build binutils-build-native-to-win64
maybe_do_build djbnu-build-native-to-dos

maybe_do_build gcc-glibc-bootstrap-native-to-lingnu32
maybe_do_build gcc-glibc-bootstrap-native-to-lingnu64
maybe_do_build gcc-musl-bootstrap-native-to-linmus32
maybe_do_build gcc-musl-bootstrap-native-to-linmus64
maybe_do_build gcc-mingw-w64-bootstrap-native-to-win32
maybe_do_build gcc-mingw-w64-bootstrap-native-to-win64
maybe_do_build gcc-djgpp-bootstrap-native-to-dos

#
# target libraries
#

maybe_do_build libffi-build-lingnu32
maybe_do_build libffi-build-lingnu64
maybe_do_build libffi-build-linmus32
maybe_do_build libffi-build-linmus64
maybe_do_build libffi-build-win32
maybe_do_build libffi-build-win64

maybe_do_build ncurses-build-lingnu32
maybe_do_build ncurses-build-lingnu64
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

maybe_do_build       inputproto-build-lingnu32
maybe_do_build          kbproto-build-lingnu32
maybe_do_build        xcb-proto-build-lingnu32
maybe_do_build        xextproto-build-lingnu32
maybe_do_build           xproto-build-lingnu32
maybe_do_build libpthread-stubs-build-lingnu32
maybe_do_build      util-macros-build-lingnu32
maybe_do_build           xtrans-build-lingnu32

maybe_do_build       inputproto-build-lingnu64
maybe_do_build          kbproto-build-lingnu64
maybe_do_build        xcb-proto-build-lingnu64
maybe_do_build        xextproto-build-lingnu64
maybe_do_build           xproto-build-lingnu64
maybe_do_build libpthread-stubs-build-lingnu64
maybe_do_build      util-macros-build-lingnu64
maybe_do_build           xtrans-build-lingnu64

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

maybe_do_build libXau-build-lingnu32
maybe_do_build libxcb-build-lingnu32
maybe_do_build libX11-build-lingnu32

maybe_do_build libXau-build-lingnu64
maybe_do_build libxcb-build-lingnu64
maybe_do_build libX11-build-lingnu64

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

maybe_do_build fbc-build-lingnu32
maybe_do_build fbc-build-lingnu64
maybe_do_build fbc-build-linmus32
maybe_do_build fbc-build-linmus64
maybe_do_build fbc-build-win32
maybe_do_build fbc-build-win64
maybe_do_build fbc-build-dos
maybe_do_build fbc-build-win32-standalone
maybe_do_build fbc-build-win64-standalone
maybe_do_build fbc-build-dos-standalone

echo "ok"
