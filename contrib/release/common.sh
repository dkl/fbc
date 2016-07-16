build_triplet=$(/usr/share/automake-1.15/config.guess)

term_color_red="$(tput setaf 1)"
term_color_green="$(tput setaf 2)"
term_color_reset="$(tput sgr0)"

my_fetch() {
	local tarball="$1"
	local url="$2"

	# download
	if [ ! -f "../downloads/$tarball" ]; then
		echo "download: $tarball"
		mkdir -p "../downloads"
		if wget "$url" -O "../downloads/$tarball" > "../downloads/$tarball.log" 2>&1; then
			:
		else
			rm -f "../downloads/$tarball"
			echo "failed, see $PWD/../downloads/$tarball.log"
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

	# unpack
	if [ ! -d "$name" ]; then
		echo "unpack: $tarball"

		# Extract archive inside tmpextract/
		rm -rf tmpextract
		mkdir tmpextract
		cd tmpextract

		case "$tarball" in
		*.zip)
			unzip -q "../../downloads/$tarball";;
		*)
			tar -xf "../../downloads/$tarball";;
		esac

		cd ..

		my_fixdir tmpextract "$name"

		# assert that these files, that we'll add, don't exist yet
		test ! -f "$name/build-patched.stamp"
		test ! -f "$name/build-done.stamp"
		test ! -f "$name/build-log.txt"
	fi
}

#
# Fix paths in *.la files and also all the *-config scripts
#
# We cross-compile stuff with a certain --prefix=... which is where it should be
# installed on the target system, and install it into our sysroot with "make
# install DESTDIR=$sysroot" so that it is available to following builds during
# the cross-compilation.
#
# libtool stores the prefix into the installed *.la files, because they are
# intended for the target system. We need to adjust them to work in the sysroot.
#
# Alternative: use libtool's sysroot support?
#
fix_la_files_and_config_scripts() {
	installdir="$1"

	for f in `find $installdir -type f -name "*.la"` \
			 `find $installdir/bin -type f -name "*-config"`; do

		sed -e "s:/usr:$prefix:g" < $f > $f.tmp

		# Overwrite original with temp file, preserve executable bit
		if [ -x "$f" ]; then
			chmod +x $f.tmp
		fi
		mv $f.tmp $f
	done
}

remove_la_files_in_dirs() {
	find "$@" -type f -name "*.la" | xargs rm -f
}
