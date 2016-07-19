#!/bin/bash
set -e

. common.sh

mkdir -p dos
cd dos

install_native="$PWD/install"
install_dos="$install_native/i586-pc-msdosdjgpp"
mkdir -p "$install_dos"
if [ ! -e "$install_dos/dev/env/DJDIR" ]; then
	mkdir -p "$install_dos/dev/env"
	ln -s ../../.. "$install_dos/dev/env/DJDIR"
fi
export PATH="$install_native/bin:$PATH"

version_gmp=6.1.0
version_mpc=1.0.3
version_mpfr=3.1.4

title_djbnu=bnu226sr3
title_djgcc=gcc610s
title_gmp=gmp-$version_gmp
title_mpc=mpc-$version_mpc
title_mpfr=mpfr-$version_mpfr
title_djlsr=djlsr205
title_djcrx=djcrx205

tarball_djbnu=$title_djbnu.zip
tarball_djgcc=$title_djgcc.zip
tarball_gmp=$title_gmp.tar.lz
tarball_mpc=$title_mpc.tar.gz
tarball_mpfr=$title_mpfr.tar.xz
tarball_djlsr=$title_djlsr.zip
tarball_djcrx=$title_djcrx.zip

my_fetch $tarball_djbnu "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2gnu/$tarball_djbnu"
my_fetch $tarball_djgcc "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2gnu/$tarball_djgcc"
my_fetch $tarball_gmp   "https://gmplib.org/download/gmp/$tarball_gmp"
my_fetch $tarball_mpc   "ftp://ftp.gnu.org/gnu/mpc/$tarball_mpc"
my_fetch $tarball_mpfr  "http://www.mpfr.org/mpfr-current/$tarball_mpfr"
my_fetch $tarball_djlsr "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/$tarball_djlsr"
my_fetch $tarball_djcrx "ftp://ftp.fu-berlin.de/pc/languages/djgpp/current/v2/$tarball_djcrx"

my_extract $title_djbnu $tarball_djbnu
my_extract $title_djgcc $tarball_djgcc
my_extract $title_gmp   $tarball_gmp
my_extract $title_mpc   $tarball_mpc
my_extract $title_mpfr  $tarball_mpfr
my_extract $title_djlsr $tarball_djlsr
my_extract $title_djcrx $tarball_djcrx

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

do_build_autotools_dos() {
	local srcname="$1"
	shift
	../"$srcname"/configure \
		--build=$build_triplet --host=i586-pc-msdosdjgpp \
		--prefix= \
		--enable-static --disable-shared "$@"
	make
	make install DESTDIR="$install_dos"
}

do_build() {
	local buildname="$1"

	case "$buildname" in

	$title_djbnu-build-native-to-dos)
		do_build_autotools_native $title_djbnu \
			--target=i586-pc-msdosdjgpp --with-sysroot="$install_dos" \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_djbnu-build-dos-to-dos)
		do_build_autotools_dos $title_djbnu \
			--target=i586-pc-msdosdjgpp \
			--disable-nls --disable-multilib --disable-werror
		;;

	$title_djcrx-build-dos)
		cp -R ../$title_djcrx/. .
		cp -R ../$title_djlsr/. .
		cd src
		rm -f gcc.opt
		make
		cd ..
		cp -R include/. "$install_dos"/include
		;;

	$title_djgcc-build-native-to-dos-gcc)
		../$title_djgcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i586-pc-msdosdjgpp \
			--prefix="$install_native" \
			--with-local-prefix="$install_native" \
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
		make all-gcc
		make install-gcc
		;;

	$title_djgcc-build-native-to-dos-full)
		../$title_djgcc/configure \
			--build=$build_triplet --host=$build_triplet --target=i586-pc-msdosdjgpp \
			--prefix="$install_native" \
			--with-local-prefix="$install_native" \
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
		make
		make install
		;;

	$title_djgcc-build-dos-to-dos)
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

	$title_gmp-build-native)  do_build_autotools_native $title_gmp;;
	$title_mpfr-build-native) do_build_autotools_native $title_mpfr --with-gmp="$install_native";;
	$title_mpc-build-native)  do_build_autotools_native $title_mpc  --with-gmp="$install_native" --with-mpfr="$install_native";;

	$title_gmp-build-dos)    do_build_autotools_dos $title_gmp;;
	$title_mpfr-build-dos)   do_build_autotools_dos $title_mpfr --with-gmp="$install_dos";;
	$title_mpc-build-dos)    do_build_autotools_dos $title_mpc  --with-gmp="$install_dos" --with-mpfr="$install_dos";;

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

# cross toolchain and needed target libs
maybe_do_build $title_djbnu-build-native-to-dos
maybe_do_build $title_gmp-build-native
maybe_do_build $title_mpfr-build-native
maybe_do_build $title_mpc-build-native
maybe_do_build $title_djgcc-build-native-to-dos-gcc
maybe_do_build $title_djcrx-build-dos
maybe_do_build $title_djgcc-build-native-to-dos-full
