#!/usr/bin/env bash
set -euo pipefail

source "${BASH_SOURCE%/*}/define-utils.sh"
source "${BASH_SOURCE%/*}/define-archs.sh"

declare -a PKG_LIBS=()
declare -a PKG_HOST=()
declare -a PKG_STUB=()

show_help() {
	stderr "Usage: ${0##*/} [-l|--library PKG_NAME]... [-p|--package PKG_NAME]..."
  stderr '                          [-s|--stub PKG_NAME]...'
	stderr 'Sets up a Docker container based on Debian for automated cross-compilation.'
	stderr
	stderr '    -h, --help              Display this help and exit'
	stderr '    -l, --library PKG_NAME  Package to be installed for every architecture'
	stderr '    -p, --package PKG_NAME  Package to be installed only for host architecture'
	stderr '    -s, --stub PKG_NAME     Package to be substituted with an empty dummy'
	if [[ $# -gt 0 ]]; then
		stderr
		stderr "$@"
		exit 1
	fi
	exit 0
}

parse_arguments() {
	local options; options=$(
		getopt --name "${0##*/}" \
		       --options 'hl:p:s:' \
					 --longoptions 'help,library:,package:,stub:' \
					 -- "$@" 2>&1 \
		| head --lines 1
	) || show_help "${options}"
	eval set -- ${options}
	while true; do
		case "${1}" in
			-h|--help)
				show_help
				;;
			-l|--library)
				shift
				for pkg_arch in "${PKG_ARCHS[@]}"; do
					PKG_LIBS+=("${1}:${pkg_arch}")
				done
				;;
			-p|--package)
				shift
				PKG_HOST+=("${1}")
				;;
			-s|--stub)
				shift
				PKG_STUB+=("${1}")
				;;
			--)
				shift
				break
				;;
		esac
		shift
	done
	if [[ $# -ne 0 ]]; then
		show_help "Unrecognized argument \"${1}\""
	fi
}

add_architectures() {
	for pkg_arch in "${PKG_ARCHS[@]}"; do
		dpkg --add-architecture "${pkg_arch}"
	done
}

upgrade_system() {
	apt-get --assume-yes update
	apt-get --assume-yes full-upgrade
	apt-get --assume-yes autoremove --purge
	apt-get --assume-yes clean
}

install_stubs() {
	if [[ ${#PKG_STUB[@]} -gt 0 ]]; then
	  apt-get --assume-yes --no-install-recommends install equivs
		cd /tmp
		for pkg_stub in "${PKG_STUB[@]}"; do
			cat <<-EOF >stub
				Package: ${pkg_stub}
				Version: 99
			EOF
			equivs-build stub
			dpkg --install "${pkg_stub}_99_all.deb"
			rm --force stub "${pkg_stub}_99_all.deb"
		done
		cd -
	fi
}

install_packages() {
	DPKG_FORCE='security-mac,downgrade,overwrite' apt-get \
	  --assume-yes --no-install-recommends install build-essential:amd64 \
		"${ARCH_GCC[@]}" "${ARCH_LIBC[@]}" "${PKG_LIBS[@]}" "${PKG_HOST[@]}"
}

cleanup() {
	if [[ ${#PKG_STUB[@]} -gt 0 ]]; then
		apt-get --assume-yes autoremove --purge equivs
	fi
}

main() {
	parse_arguments "$@"
	add_architectures
	upgrade_system
	install_stubs
	install_packages
	cleanup
}

main "$@"
