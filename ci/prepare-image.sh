#!/usr/bin/env bash
set -euox pipefail

stderr() {
	cat <<< "$@" 1>&2
}

main() {
	# Read script parameters
	if [[ -n "${1}" ]]; then
		local arch="${1}"
		local dist="${2:-focal}"
	else
		stderr "Usage: ${0} TARGET_PLATFORM [TARGET_DIST]"
		stderr 'Prepares a docker image for compiling the hunter file manager.'
		exit 1
	fi

	# Edit the package manager's list of native and foreign package sources
	cat <<-EOF >/etc/apt/sources.list
		deb [arch=amd64,i386] http://archive.ubuntu.com/ubuntu/ ${dist} main restricted universe multiverse
		deb [arch=amd64,i386] http://archive.ubuntu.com/ubuntu/ ${dist}-updates main restricted universe multiverse
		deb [arch=amd64,i386] http://archive.ubuntu.com/ubuntu/ ${dist}-backports main restricted universe multiverse
		deb [arch=amd64,i386] http://security.ubuntu.com/ubuntu/ ${dist}-security main restricted universe multiverse
	EOF
	cat <<-EOF >/etc/apt/sources.list.d/ports.list
		deb [arch-=amd64,i386] http://ports.ubuntu.com/ubuntu-ports/ ${dist} main restricted universe multiverse
		deb [arch-=amd64,i386] http://ports.ubuntu.com/ubuntu-ports/ ${dist}-updates main restricted universe multiverse
		deb [arch-=amd64,i386] http://ports.ubuntu.com/ubuntu-ports/ ${dist}-backports main restricted universe multiverse
		deb [arch-=amd64,i386] http://ports.ubuntu.com/ubuntu-ports/ ${dist}-security main restricted universe multiverse
	EOF

	# Add target platform and resynchronize the list of packages
	dpkg --add-architecture "${arch}"
	apt-get --assume-yes update

	# Upgrade outdated packages; remove obsolete ones; clear the download cache
	apt-get --assume-yes dist-upgrade
	apt-get --assume-yes autoremove --purge
	apt-get --assume-yes clean

	# Install the libgstreamer and libsixel packages for the target platform
	apt-get --assume-yes install \
		"gstreamer1.0-libav:${arch}" \
		"gstreamer1.0-plugins-bad:${arch}" \
		"gstreamer1.0-plugins-base:${arch}" \
		"gstreamer1.0-plugins-good:${arch}" \
		"gstreamer1.0-plugins-ugly:${arch}" \
		"libgstreamer1.0-dev:${arch}" \
		"libgstreamer-plugins-base1.0-dev:${arch}" \
		"libgstrtspserver-1.0-dev:${arch}" \
		"libsixel-dev:${arch}"

	# Remove the libopencvX.Y-java dependency from the libopencv-dev package,
	# because it isn't properly configured for multi-architecture systems and
	# would prevent libgstreamer-plugins-bad1.0-dev from installing
	local pkg_pattern='s/(libopencv[0-9.]+-java)(\s+\([^)]+\))?(\s*,\s*)?//'
	cd /tmp
	apt-get --assume-yes download "libopencv-dev:${arch}"
	dpkg-deb --extract libopencv-dev_*.deb ./libopencv-dev
	dpkg-deb --control libopencv-dev_*.deb ./libopencv-dev/DEBIAN
	sed --in-place --regexp-extended "${pkg_pattern}" ./libopencv-dev/DEBIAN/control
	dpkg --build ./libopencv-dev ./libopencv-dev.deb
	apt-get --assume-yes install ./libopencv-dev.deb
	rm --recursive --force ./libopencv-dev*
	cd -

	# Install prerequisites for gstreamer-player
	apt-get --assume-yes install "libgstreamer-plugins-bad1.0-dev:${arch}"
}

main "$@"
