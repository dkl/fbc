#!/bin/bash
# Requirements:
#  wget, unzip, xz-utils, lzip
#  gcc, g++, bison, flex, texinfo (makeinfo), pkg-config
#  zlib-dev

set -e

buildgoals=
SHOW_LOGS=no
while [ "$#" -gt 0 ]; do
	case "$1" in
	--show-logs)
		SHOW_LOGS=yes
		;;
	-*)
		echo "unknown/unexpected command line argument '$1'"
		exit 1
		;;
	*)
		if [ -n "$buildgoals" ]; then
			echo "too many build goals"
			exit 1
		fi
		buildgoals="$1"
		;;
	esac
	shift
done

my_fetch() {
	local tarball="$1"
	local url="$2"
	if [ ! -f "../downloads/$tarball" ]; then
		echo "download: $tarball"
		mkdir -p "../downloads"
		if wget "$url" -O "../downloads/$tarball" > "../downloads/$tarball.log" 2>&1; then
			chmod -w "../downloads/$tarball"
		else
			rm -f "../downloads/$tarball"
			echo
			echo "failed:"
			echo
			cat "$PWD/../downloads/$tarball.log"
			exit 1
		fi
	fi
}

my_fixdir() {
	local top="$1"
	local name="$2"
	cd "$top"
	# If the archive included one or multiple prefix directories,
	# remove them
	# Just one dir in current dir?
	# (note: ignoring hidden files here, which helps at least with some
	# packages that have .hg_archival.txt etc. at the toplevel but all other
	# files in a subdir)
	if [ "`ls -1 | wc -l`" = "1" ] && [ -d "`ls -1`" ]; then
		# Recursion to handle nested dirs
		my_fixdir "`ls -1`" "$name"
		mv "$name" ..
		cd ..
		rm -rf "$top"
	else
		cd ..
		if [ "$top" != "$name" ]; then
			mv "$top" "$name"
		fi
	fi
}

my_extract() {
	local name="$1"
	local tarball="$2"
	if [ ! -d "$name" ]; then
		echo "unpack: $tarball"
		# Extract archive inside tmpextract/
		rm -rf tmpextract
		mkdir tmpextract
		cd tmpextract
		case "$tarball" in
		*.zip) unzip -q "../../downloads/$tarball";;
		*)     tar -xf  "../../downloads/$tarball";;
		esac
		cd ..
		my_fixdir tmpextract "$name"
	fi
}

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

		if [ "$SHOW_LOGS" = "yes" ]; then
			do_patch "$srcdirname"
		else
			do_patch "$srcdirname" > patch-log.txt 2>&1
		fi

		touch patch-done.stamp
		cd ..
	fi
}

fetch_extract_custom() {
	finaldir=$1
	title=$2
	tarballext=$3
	urlpattern="$4"

	tarball=$title.$tarballext
	url="$(printf "$urlpattern" $tarball)"

	my_fetch $tarball "$url"
	my_extract $finaldir $tarball

	maybe_do_patch $finaldir
}

fetch_extract() {
	name=$1
	version=$2
	tarballext=$3
	urlpattern="$4"

	title=$name-$version

	fetch_extract_custom $name $title $tarballext "$urlpattern"
}

remove_la_files_in_dirs() {
	find "$@" -type f -name "*.la" | xargs rm -f
}

################################################################################

mkdir -p build
cd build
mkdir -p output

fbc_version=d8687286e53e916b91ee43b15c40cb25cffa6adc
fetch_extract_custom fbc fbc-$fbc_version tar.gz "https://github.com/freebasic/fbc/archive/$fbc_version.tar.gz"
#fetch_extract_custom fbc FreeBASIC-1.05.0-source tar.xz "https://sourceforge.net/projects/fbc/files/Source%%20Code/%s/download"

if [ ! -f ../downloads/config.guess ]; then
	wget -O ../downloads/config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
	chmod +x ../downloads/config.guess
fi

if [ ! -f ../downloads/config.sub ]; then
	wget -O ../downloads/config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
	chmod +x ../downloads/config.sub
fi

fetch_extract binutils  2.27   tar.bz2  "http://ftpmirror.gnu.org/binutils/%s"
fetch_extract gcc       6.2.0  tar.bz2  "http://ftpmirror.gnu.org/gcc/gcc-6.2.0/%s"
fetch_extract glibc     2.24   tar.xz   "http://ftp.gnu.org/gnu/glibc/%s"
fetch_extract linux     4.7.3  tar.xz   "https://cdn.kernel.org/pub/linux/kernel/v4.x/%s"
fetch_extract mingw-w64 v4.0.6 tar.bz2  "https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/%s/download"
fetch_extract musl      1.1.15 tar.gz   "https://www.musl-libc.org/releases/%s"
fetch_extract_custom djcrx djcrx205  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/%s"
fetch_extract_custom djlsr djlsr205  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/%s"
fetch_extract_custom djbnu bnu226sr3 zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/v2gnu/%s"
fetch_extract_custom djgcc gcc620s   zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/v2gnu/%s"

#fetch_extract_custom djgcc_prebuilt gcc620b  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2gnu/%s"
#fetch_extract_custom djgpp_prebuilt gpp620b  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2gnu/%s"
fetch_extract_custom djbnu_prebuilt bnu227b  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/v2gnu/%s"
#fetch_extract_custom djdev_prebuilt djdev205 zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/%s"
my_fetch ../downloads/bnu227s.zip                "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/v2gnu/bnu227s.zip"

#fetch_extract_custom djcrx djcrx204  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/beta/v2/%s"
#fetch_extract_custom djlsr djlsr204  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/beta/v2/%s"
#fetch_extract_custom djbnu bnu2251s  zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/beta/v2gnu/%s"
#fetch_extract_custom djgcc gcc492s   zip "ftp://ftp.fu-berlin.de/pc/languages/djgpp/deleted/beta/v2gnu/%s"

fetch_extract libffi  3.2.1  tar.gz   "ftp://sourceware.org/pub/libffi/%s"
#fetch_extract_custom llvm llvm-3.9.1.src tar.xz "http://releases.llvm.org/3.9.1/%s"

fetch_extract gmp       6.1.1  tar.lz   "https://gmplib.org/download/gmp/%s"
fetch_extract mpc       1.0.3  tar.gz   "ftp://ftp.gnu.org/gnu/mpc/%s"
fetch_extract mpfr      3.1.4  tar.xz   "http://www.mpfr.org/mpfr-3.1.4/%s"

fetch_extract expat   2.2.0  tar.bz2 "https://sourceforge.net/projects/expat/files/expat/2.2.0/%s/download"
fetch_extract libxml2 2.9.4  tar.gz  "ftp://xmlsoft.org/libxml2/%s"
fetch_extract libxslt 1.1.29 tar.gz  "ftp://xmlsoft.org/libxml2/%s"

fetch_extract zlib   1.2.8  tar.xz "http://prdownloads.sourceforge.net/libpng/%s?download"
fetch_extract bzip2  1.0.6  tar.gz "http://www.bzip.org/1.0.6/%s"
fetch_extract libzip 1.1.3  tar.xz "https://nih.at/libzip/%s"
fetch_extract lzo    2.09   tar.gz "http://www.oberhumer.com/opensource/lzo/download/%s"
fetch_extract xz     5.2.2  tar.xz "http://tukaani.org/xz/%s"

fetch_extract gpm     1.99.7 tar.lzma "http://www.nico.schottelius.org/software/gpm/archives/%s"
fetch_extract ncurses 6.0    tar.gz   "http://ftp.gnu.org/gnu/ncurses/%s"

fetch_extract harfbuzz   1.4.2  tar.bz2 "https://www.freedesktop.org/software/harfbuzz/release/%s"
fetch_extract freetype   2.7.1  tar.bz2 "https://sourceforge.net/projects/freetype/files/freetype2/2.7.1/%s/download"
fetch_extract fontconfig 2.12.1 tar.gz  "https://www.freedesktop.org/software/fontconfig/release/%s"

fetch_extract libpng 1.6.28 tar.xz  "http://prdownloads.sourceforge.net/libpng/%s?download"
fetch_extract giflib 5.1.4  tar.bz2 "https://sourceforge.net/projects/giflib/files/%s/download"
fetch_extract tiff   4.0.7  tar.gz  "http://download.osgeo.org/libtiff/%s"
fetch_extract_custom jpeg-9b jpegsrc.v9b tar.gz "http://www.ijg.org/files/%s"

fetch_extract damageproto      1.2.1  tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract dri2proto        2.8    tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract dri3proto        1.0    tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract fixesproto       5.0    tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract glproto          1.4.17 tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract glu              9.0.0  tar.bz2 "https://mesa.freedesktop.org/archive/glu/%s"
fetch_extract inputproto       2.3.2  tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract kbproto          1.0.7  tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract libdrm           2.4.75 tar.gz  "https://dri.freedesktop.org/libdrm/%s"
fetch_extract libICE           1.0.9  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract liblbxutil       1.1.0  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libpciaccess     0.13.4 tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libpthread-stubs 0.3    tar.bz2 "https://xcb.freedesktop.org/dist/%s"
fetch_extract libSM            1.2.2  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libX11           1.6.3  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXau           1.0.8  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libxcb           1.12   tar.bz2 "https://xcb.freedesktop.org/dist/%s"
fetch_extract libXcursor       1.1.14 tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXdamage       1.1.4  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXdmcp         1.1.2  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXext          1.3.3  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXfixes        5.0.2  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXft           2.3.2  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXi            1.7.6  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXinerama      1.1.3  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXmu           1.1.2  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXpm           3.5.11 tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXrandr        1.5.0  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXrender       0.9.9  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libxshmfence     1.2    tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXt            1.1.5  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXtst          1.2.2  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXv            1.0.10 tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXxf86dga      1.1.4  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract libXxf86vm       1.1.4  tar.bz2 "https://www.x.org/releases/individual/lib/%s"
fetch_extract mesa             13.0.4 tar.xz  "https://mesa.freedesktop.org/archive/13.0.4/%s"
fetch_extract presentproto     1.1    tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract randrproto       1.5.0  tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract recordproto      1.14.2 tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract renderproto      0.11.1 tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract util-macros      1.19.0 tar.bz2 "https://www.x.org/releases/individual/util/%s"
fetch_extract videoproto       2.3.3  tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract xcb-proto        1.12   tar.bz2 "https://xcb.freedesktop.org/dist/%s"
fetch_extract xextproto        7.3.0  tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract xf86dgaproto     2.1    tar.bz2 "https://www.x.org/releases/individual/proto/%s"
fetch_extract xf86vidmodeproto 2.3.1  tar.bz2 "https://www.x.org/releases/individual/proto/%s"
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
mkdir -p "$sysroot_dos/dev/env"
[ ! -e "$sysroot_win32/mingw"       ] && ln -s "$sysroot_win32"       "$sysroot_win32/mingw"
[ ! -e "$sysroot_win64/mingw"       ] && ln -s "$sysroot_win64"       "$sysroot_win64/mingw"
[ ! -e "$sysroot_dos/dev/env/DJDIR" ] && ln -s "$sysroot_dos"         "$sysroot_dos/dev/env/DJDIR"
[ ! -e "$sysroot_dos/sys-include"   ] && ln -s "$sysroot_dos/include" "$sysroot_dos/sys-include"
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

	# 1. cross-compiler gcc/g++
	# 2. target linux headers (requires the cross-gcc for some reason?)
	# 3. target glibc headers & crt1.o (requires gcc to compile .o's)
	# 4. target libgcc.a (requires gcc and headers)
	# 5. target libc.so (requires libgcc)
	# 6. target libstdc++.so (requires libc)

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
		--enable-static --enable-shared=libstdc++ \
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

zlib_win_build() {
	additionalnativeprefix="$1"
	triplet="$2"
	sysroot="$3"
	cp -R ../zlib/. .
	prepend_path "$additionalnativeprefix"/bin
	make -f win32/Makefile.gcc libz.a install \
		PREFIX="$triplet"- \
		BINARY_PATH=/bin INCLUDE_PATH=/include LIBRARY_PATH=/lib DESTDIR="$sysroot"
}

zlib_unix_build() {
	additionalnativeprefix="$1"
	shift
	triplet="$1"
	shift
	sysroot="$1"
	shift
	cp -R ../zlib/. .
	prepend_path "$additionalnativeprefix"/bin
	CHOST="$triplet" ./configure "$@"
	make
	make install DESTDIR="$sysroot"
}

bzip2_build() {
	additionalnativeprefix="$1"
	triplet="$2"
	sysrootprefix="$3"
	prepend_path "$additionalnativeprefix"/bin
	local CC="$triplet-gcc"
	local AR="$triplet-ar"
	local S="../bzip2"
	"$CC" $CFLAGS -D_FILE_OFFSET_BITS=64 -c $S/blocksort.c $S/huffman.c $S/crctable.c $S/randtable.c $S/compress.c $S/decompress.c $S/bzlib.c
	"$AR" rcs libbz2.a blocksort.o huffman.o crctable.o randtable.o compress.o decompress.o bzlib.o
	cp $S/bzlib.h "$sysrootprefix/include"
	cp libbz2.a "$sysrootprefix/lib"
}

do_build() {
	local buildname="$1"
	local source="$(echo "$buildname" | sed -e 's/-[^-]*$//g')"
	local target="$(echo "$buildname" | sed -e 's/^.*-//g')"

	ORIG_PATH="$PATH"

	case "$buildname" in

	binutils-native-to-lingnu32) do_build_autotools_native binutils --target=i686-pc-linux-gnu    --program-prefix=i686-pc-linux-gnu-    --prefix="$prefix_cross_lingnu32" --with-sysroot="$sysroot_lingnu32" $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-native-to-lingnu64) do_build_autotools_native binutils --target=x86_64-pc-linux-gnu  --program-prefix=x86_64-pc-linux-gnu-  --prefix="$prefix_cross_lingnu64" --with-sysroot="$sysroot_lingnu64" $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-native-to-linmus32) do_build_autotools_native binutils --target=i686-pc-linux-musl   --program-prefix=i686-pc-linux-musl-   --prefix="$prefix_cross_linmus32" --with-sysroot="$sysroot_linmus32" $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-native-to-linmus64) do_build_autotools_native binutils --target=x86_64-pc-linux-musl --program-prefix=x86_64-pc-linux-musl- --prefix="$prefix_cross_linmus64" --with-sysroot="$sysroot_linmus64" $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-native-to-win32   ) do_build_autotools_native binutils --target=i686-w64-mingw32     --program-prefix=i686-w64-mingw32-     --prefix="$prefix_cross_win32"    --with-sysroot="$sysroot_win32"    $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-native-to-win64   ) do_build_autotools_native binutils --target=x86_64-w64-mingw32   --program-prefix=x86_64-w64-mingw32-   --prefix="$prefix_cross_win64"    --with-sysroot="$sysroot_win64"    $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-win32-to-win32    ) do_build_autotools_win32  binutils --target=i686-w64-mingw32   $binutils_conf; remove_non_prefixed_cross_tools;;
	binutils-win64-to-win64    ) do_build_autotools_win64  binutils --target=x86_64-w64-mingw32 $binutils_conf; remove_non_prefixed_cross_tools;;

	binutils-native-to-dos)
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

	gcc-native-to-lingnu32) gcc_glibc_bootstrap i686-pc-linux-gnu    i386   "$prefix_cross_lingnu32" "$sysroot_lingnu32";;
	gcc-native-to-lingnu64) gcc_glibc_bootstrap x86_64-pc-linux-gnu  x86_64 "$prefix_cross_lingnu64" "$sysroot_lingnu64";;
	gcc-native-to-linmus32) gcc_musl_bootstrap  i686-pc-linux-musl   i386   "$prefix_cross_linmus32" "$sysroot_linmus32";;
	gcc-native-to-linmus64) gcc_musl_bootstrap  x86_64-pc-linux-musl x86_64 "$prefix_cross_linmus64" "$sysroot_linmus64";;
	gcc-native-to-win32) gcc_mingww64_bootstrap i686-w64-mingw32   "$prefix_cross_win32" "$sysroot_win32";;
	gcc-native-to-win64) gcc_mingww64_bootstrap x86_64-w64-mingw32 "$prefix_cross_win64" "$sysroot_win64";;
	gcc-native-to-dos) gcc_djgpp_bootstrap;;

	gcc-win32-to-win32)
		do_build_autotools_win32 gcc \
			--target=i686-w64-mingw32 \
			--with-local-prefix= \
			--with-build-sysroot="$sysroot_win32" \
			--with-gmp="$sysroot_win32" \
			--with-mpfr="$sysroot_win32" \
			--with-mpc="$sysroot_win32" \
			$gcc_conf $gcc_conf_windows
		;;

	gcc-win64-to-win64)
		do_build_autotools_win64 gcc \
			--target=x86_64-w64-mingw32 \
			--with-local-prefix= \
			--with-build-sysroot="$sysroot_win64" \
			--with-gmp="$sysroot_win64" \
			--with-mpfr="$sysroot_win64" \
			--with-mpc="$sysroot_win64" \
			$gcc_conf $gcc_conf_windows
		;;

	fbc-native)
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

	fbc-lingnu32)
		prepend_path "$prefix_native"/bin
		prepend_path "$prefix_cross_lingnu32"/bin
		echo "TARGET=i686-pc-linux-gnu" > config.mk
		make -f ../fbc/makefile -j"$cpucount"
		make -f ../fbc/makefile bindist
		cp *.tar.gz *.tar.xz ../output
		cp ../fbc/contrib/manifest/FreeBASIC-linux-x86.lst ../output
		;;

	fbc-lingnu64)
		prepend_path "$prefix_native"/bin
		prepend_path "$prefix_cross_lingnu64"/bin
		echo "TARGET=x86_64-pc-linux-gnu" > config.mk
		make -f ../fbc/makefile -j"$cpucount"
		make -f ../fbc/makefile bindist
		cp *.tar.gz *.tar.xz ../output
		cp ../fbc/contrib/manifest/FreeBASIC-linux-x86_64.lst ../output
		;;

	fbc-linmus32)
		prepend_path "$prefix_native"/bin
		prepend_path "$prefix_cross_linmus32"/bin
		echo "TARGET=i686-pc-linux-musl" > config.mk
		make -f ../fbc/makefile -j"$cpucount"
		make -f ../fbc/makefile bindist
		cp *.tar.gz *.tar.xz ../output
		cp ../fbc/contrib/manifest/FreeBASIC-linux-x86.lst ../output/FreeBASIC-linuxmusl-x86.lst
		;;

	fbc-linmus64)
		prepend_path "$prefix_native"/bin
		prepend_path "$prefix_cross_linmus64"/bin
		echo "TARGET=x86_64-pc-linux-musl" > config.mk
		make -f ../fbc/makefile -j"$cpucount"
		make -f ../fbc/makefile bindist
		cp *.tar.gz *.tar.xz ../output
		cp ../fbc/contrib/manifest/FreeBASIC-linux-x86_64.lst ../output/FreeBASIC-linuxmusl-x86_64.lst
		;;

	fbc-win32)
		prepend_path "$prefix_native"/bin
		prepend_path "$prefix_cross_win32"/bin
		echo "TARGET=i686-w64-mingw32" > config.mk
		make -f ../fbc/makefile -j"$cpucount"
		make -f ../fbc/makefile bindist
		cp *.zip *.7z ../output
		cp ../fbc/contrib/manifest/fbc-win32.lst ../output
		;;

	fbc-win64)
		prepend_path "$prefix_native"/bin
		prepend_path "$prefix_cross_win64"/bin
		echo "TARGET=x86_64-w64-mingw32" > config.mk
		make -f ../fbc/makefile -j"$cpucount"
		make -f ../fbc/makefile bindist
		cp *.zip *.7z ../output
		cp ../fbc/contrib/manifest/fbc-win64.lst ../output
		;;

	fbc-dos)
		prepend_path "$prefix_native"/bin
		prepend_path "$prefix_cross_dos"/bin
		echo "TARGET=i586-pc-msdosdjgpp" > config.mk
		make -f ../fbc/makefile -j"$cpucount"
		make -f ../fbc/makefile bindist
		cp *.zip ../output
		cp ../fbc/contrib/manifest/fbc-dos.lst ../output
		;;

	fbc-win32-standalone)
		prepend_path "$prefix_native"/bin
		prepend_path "$prefix_cross_win32"/bin

		echo "TARGET=i686-w64-mingw32" > config.mk
		echo "ENABLE_STANDALONE=1" >> config.mk
		make -j"$cpucount" -f ../fbc/makefile

		mkdir -p bin/win32
		for i in as ar ld dlltool gprof; do
			cp "$sysroot_win32"/bin/$i.exe bin/win32/
		done
		for i in crt2 dllcrt2 gcrt2; do
			cp "$sysroot_win32"/lib/$i.o lib/win32/
		done
		for i in libgcc.a crtbegin.o crtend.o; do
			cp "$sysroot_win32"/lib/gcc/i686-w64-mingw32/*/$i lib/win32/
		done
		cp "$sysroot_win32"/lib/*.a lib/win32/
		make -f ../fbc/makefile bindist
		cp *.zip *.7z ../output
		cp ../fbc/contrib/manifest/FreeBASIC-win32.lst ../output
		;;

	fbc-win64-standalone)
		prepend_path "$prefix_native"/bin
		prepend_path "$prefix_cross_win64"/bin

		echo "TARGET=x86_64-w64-mingw32" > config.mk
		echo "ENABLE_STANDALONE=1" >> config.mk
		make -j"$cpucount" -f ../fbc/makefile

		mkdir -p bin/win64
		for i in as ar ld dlltool gprof; do
			cp "$sysroot_win64"/bin/$i.exe bin/win64/
		done
		for i in crt2 dllcrt2 gcrt2; do
			cp "$sysroot_win64"/lib/$i.o lib/win64/
		done
		for i in libgcc.a crtbegin.o crtend.o; do
			cp "$sysroot_win64"/lib/gcc/x86_64-w64-mingw32/*/$i lib/win64/
		done
		cp "$sysroot_win64"/lib/*.a lib/win64/
		make -f ../fbc/makefile bindist
		cp *.zip *.7z ../output
		cp ../fbc/contrib/manifest/FreeBASIC-win64.lst ../output
		;;

	fbc-dos-standalone)
		prepend_path "$prefix_native"/bin
		prepend_path "$prefix_cross_dos"/bin

		echo "TARGET=i586-pc-msdosdjgpp" > config.mk
		echo "ENABLE_STANDALONE=1" >> config.mk
		make -j"$cpucount" -f ../fbc/makefile

		mkdir -p bin/dos
		# Use DJGPP's prebuilt binaries, instead of cross-compiling
		# TODO: Find out why the cross-compiled DJGPP binutils didn't work,
		# e.g. ld.exe didn't recognize COFF objects...
		for i in ar as gprof ld; do
			cp ../djbnu_prebuilt/bin/$i.exe bin/dos/
		done
		cp "$sysroot_dos"/lib/crt0.o lib/dos/
		cp "$sysroot_dos"/lib/gcrt0.o lib/dos/
		cp "$prefix_cross_dos"/i586-pc-msdosdjgpp/lib/libstdc++.a lib/dos/libstdcx.a
		cp "$prefix_cross_dos"/i586-pc-msdosdjgpp/lib/libsupc++.a lib/dos/libsupcx.a
		cp "$prefix_cross_dos"/lib/gcc/i586-pc-msdosdjgpp/*/libgcc.a lib/dos/
		cp "$sysroot_dos"/lib/*.a lib/dos/
		make -f ../fbc/makefile bindist
		cp *.zip ../output
		cp ../fbc/contrib/manifest/FreeBASIC-dos.lst ../output
		;;

	mpfr-native) do_build_autotools_native mpfr --with-gmp="$prefix_native" --prefix="$prefix_native";;
	mpfr-win32 ) do_build_autotools_win32  mpfr --with-gmp="$sysroot_win32";;
	mpfr-win64 ) do_build_autotools_win64  mpfr --with-gmp="$sysroot_win64";;
	mpfr-dos   ) do_build_autotools_dos    mpfr --with-gmp="$sysroot_dos"  ;;

	mpc-native) do_build_autotools_native mpc --with-gmp="$prefix_native" --with-mpfr="$prefix_native" --prefix="$prefix_native";;
	mpc-win32 ) do_build_autotools_win32  mpc --with-gmp="$sysroot_win32" --with-mpfr="$sysroot_win32";;
	mpc-win64 ) do_build_autotools_win64  mpc --with-gmp="$sysroot_win64" --with-mpfr="$sysroot_win64";;
	mpc-dos   ) do_build_autotools_dos    mpc --with-gmp="$sysroot_dos"   --with-mpfr="$sysroot_dos"  ;;

	ncurses-lingnu32) do_build_autotools_lingnu32 ncurses --with-install-prefix="$sysroot_lingnu32" $ncurses_conf;;
	ncurses-lingnu64) do_build_autotools_lingnu64 ncurses --with-install-prefix="$sysroot_lingnu64" $ncurses_conf;;
	ncurses-linmus32) do_build_autotools_linmus32 ncurses --with-install-prefix="$sysroot_linmus32" $ncurses_conf;;
	ncurses-linmus64) do_build_autotools_linmus64 ncurses --with-install-prefix="$sysroot_linmus64" $ncurses_conf;;

	gpm-header)
		cp ../gpm/src/headers/gpm.h "$sysroot_lingnu32"/usr/include
		cp ../gpm/src/headers/gpm.h "$sysroot_lingnu64"/usr/include
		cp ../gpm/src/headers/gpm.h "$sysroot_linmus32"/usr/include
		cp ../gpm/src/headers/gpm.h "$sysroot_linmus64"/usr/include
		;;

	libffi-lingnu32) do_build_autotools_lingnu32 libffi; mv "$sysroot_lingnu32"/usr/lib/libffi-*/include/* "$sysroot_lingnu32"/usr/include;;
	libffi-lingnu64) do_build_autotools_lingnu64 libffi; mv "$sysroot_lingnu64"/usr/lib/libffi-*/include/* "$sysroot_lingnu64"/usr/include;;
	libffi-linmus32) do_build_autotools_linmus32 libffi; mv "$sysroot_linmus32"/usr/lib/libffi-*/include/* "$sysroot_linmus32"/usr/include;;
	libffi-linmus64) do_build_autotools_linmus64 libffi; mv "$sysroot_linmus64"/usr/lib/libffi-*/include/* "$sysroot_linmus64"/usr/include;;
	libffi-win32   ) do_build_autotools_win32    libffi; mv "$sysroot_win32"/lib/libffi-*/include/* "$sysroot_win32"/include;;
	libffi-win64   ) do_build_autotools_win64    libffi; mv "$sysroot_win64"/lib/libffi-*/include/* "$sysroot_win64"/include;;

	zlib-win32) zlib_win_build "$prefix_cross_win32" i686-w64-mingw32   "$sysroot_win32";;
	zlib-win64) zlib_win_build "$prefix_cross_win64" x86_64-w64-mingw32 "$sysroot_win64";;
	zlib-dos)      zlib_unix_build "$prefix_cross_dos"      i586-pc-msdosdjgpp   "$sysroot_dos"      --static --prefix=;;
	zlib-lingnu32) zlib_unix_build "$prefix_cross_lingnu32" i686-pc-linux-gnu    "$sysroot_lingnu32" --prefix=/usr;;
	zlib-lingnu64) zlib_unix_build "$prefix_cross_lingnu64" x86_64-pc-linux-gnu  "$sysroot_lingnu64" --prefix=/usr;;
	zlib-linmus32) zlib_unix_build "$prefix_cross_linmus32" i686-pc-linux-musl   "$sysroot_linmus32" --static --prefix=/usr;;
	zlib-linmus64) zlib_unix_build "$prefix_cross_linmus64" x86_64-pc-linux-musl "$sysroot_linmus64" --static --prefix=/usr;;

	bzip2-win32)    bzip2_build "$prefix_cross_win32"    i686-w64-mingw32     "$sysroot_win32"   ;;
	bzip2-win64)    bzip2_build "$prefix_cross_win64"    x86_64-w64-mingw32   "$sysroot_win64"   ;;
	bzip2-dos)      bzip2_build "$prefix_cross_dos"      i586-pc-msdosdjgpp   "$sysroot_dos"     ;;
	bzip2-lingnu32) bzip2_build "$prefix_cross_lingnu32" i686-pc-linux-gnu    "$sysroot_lingnu32";;
	bzip2-lingnu64) bzip2_build "$prefix_cross_lingnu64" x86_64-pc-linux-gnu  "$sysroot_lingnu64";;
	bzip2-linmus32) bzip2_build "$prefix_cross_linmus32" i686-pc-linux-musl   "$sysroot_linmus32";;
	bzip2-linmus64) bzip2_build "$prefix_cross_linmus64" x86_64-pc-linux-musl "$sysroot_linmus64";;

	mesa-*)
		# Failed to build and we don't need it
		local conf="--disable-egl"

		# Disable Gallium/LLVM stuff
		#  - prevents it from using [target-]llvm-config
		#  - we don't have to cross-compile LLVM (cmake...)
		conf="$conf --without-gallium-drivers --disable-gallium-llvm"
		conf="$conf --disable-llvm-shared-libs --without-clang-libdir --without-llvm-prefix"

		do_build_autotools_$target mesa $conf
		;;

	libX*) do_build_autotools_$target $source --disable-malloc0returnsnull;;

	*proto-lingnu32)
		prepend_path "$prefix_cross_lingnu32"/bin
		PKG_CONFIG=i686-pc-linux-gnu-pkg-config \
		../"${buildname%-lingnu32}"/configure \
			--build=$build_triplet --host=i686-pc-linux-gnu --prefix=/usr
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_lingnu32"
		;;

	*proto-lingnu64)
		prepend_path "$prefix_cross_lingnu64"/bin
		PKG_CONFIG=x86_64-pc-linux-gnu-pkg-config \
		../"${buildname%-lingnu64}"/configure \
			--build=$build_triplet --host=x86_64-pc-linux-gnu --prefix=/usr
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_lingnu64"
		;;

	*proto-linmus32)
		prepend_path "$prefix_cross_linmus32"/bin
		PKG_CONFIG=i686-pc-linux-musl-pkg-config \
		../"${buildname%-linmus32}"/configure \
			--build=$build_triplet --host=i686-pc-linux-musl --prefix=/usr
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linmus32"
		;;

	*proto-linmus64)
		prepend_path "$prefix_cross_linmus64"/bin
		PKG_CONFIG=x86_64-pc-linux-musl-pkg-config \
		../"${buildname%-linmus64}"/configure \
			--build=$build_triplet --host=x86_64-pc-linux-musl --prefix=/usr
		make -j"$cpucount"
		make -j"$cpucount" install DESTDIR="$sysroot_linmus64"
		;;

	gmp-native) do_build_autotools_native gmp --prefix="$prefix_native";;
	gmp-*) export CC_FOR_BUILD="gcc" CPP_FOR_BUILD="cpp"; do_build_autotools_$target gmp;;

	# Disable python binding because their "make install" doesn't fully respect DESTDIR
	libxml2-native) do_build_autotools_$target $source --prefix="$prefix_native" --without-python;;
	libxml2-*) do_build_autotools_$target $source --without-python;;

	*-native)
		do_build_autotools_$target $source --prefix="$prefix_native"
		;;
	*)
		do_build_autotools_$target $source
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

		if [ "$SHOW_LOGS" = "yes" ]; then
			do_build "$buildname"
		else
			do_build "$buildname" > build-log.txt 2>&1
		fi

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

for i in $(../get_task_list.py $buildgoal); do
	maybe_do_build $i
done

echo "ok"
