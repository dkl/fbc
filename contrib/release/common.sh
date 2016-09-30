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

fetch_extract_custom() {
	finaldir=$1
	title=$2
	tarballext=$3
	urlpattern="$4"

	tarball=$title.$tarballext
	url="$(printf "$urlpattern" $tarball)"

	my_fetch $tarball "$url"
	my_extract $finaldir $tarball
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
