#!/bin/bash
set -ex

case "$1" in
32|64)
	sudo apt-get -y install \
		libgl1-mesa-dev \
		libglu1-mesa-dev \
		libgpm-dev

	case "$1" in
	32)
		sudo apt-get -y install \
			gcc-multilib \
			lib32ncurses5-dev \
			libffi-dev:i386 \
			libcunit1-dev:i386 \
			libx11-dev:i386 \
			libxext-dev:i386 \
			libxpm-dev:i386 \
			libxrender-dev:i386 \
			libxrandr-dev:i386
		;;
	64)
		sudo apt-get -y install \
			libncurses-dev \
			libffi-dev \
			libcunit1-dev \
			libx11-dev \
			libxext-dev \
			libxpm-dev \
			libxrender-dev \
			libxrandr-dev
		;;
	esac

	source "$(dirname "$0")/bootstrap-settings.sh"

	wget -O $bootstrap_package.tar.xz \
		https://github.com/freebasic/fbc/releases/download/$bootstrap_version/$bootstrap_package.tar.xz
	tar xf $bootstrap_package.tar.xz

	cd $bootstrap_package
	if [ "$1" = "32" ]; then
		echo "CC = gcc -m32" > config.mk
		echo "AS = as --32" >> config.mk
		echo "TARGET_ARCH = x86" >> config.mk
	fi
	make -j$(nproc) bootstrap
	cd ..
	;;

crossbuild)
	sudo apt-get -y install wget xz-utils lzip p7zip-full \
		gcc g++ patch make autoconf automake libtool bison flex texinfo cmake
	;;
esac
