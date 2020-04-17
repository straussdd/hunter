#!/usr/bin/env bash
set -euo pipefail

source "${BASH_SOURCE%/*}/define-utils.sh"
source "${BASH_SOURCE%/*}/define-archs.sh"

show_help() {
	stderr "Usage: ${0##*/}"
	stderr 'Sets up multiple Rust toolchains for automated cross-compilation.'
	stderr
	stderr '    -h, --help  Display this help and exit'
	if [[ $# -gt 0 ]]; then
		stderr
		stderr "$@"
		exit 1
	fi
	exit 0
}

parse_arguments() {
	local options; options=$(
		getopt --name "${0##*/}" --options 'h' --longoptions 'help' -- "$@" 2>&1 \
		| head --lines 1
	) || show_help "${options}"
	eval set -- ${options}
	while true; do
		case "${1}" in
			-h|--help)
				show_help
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

install_rust() {
	hub clone
	PKG_CONFIG_ALLOW_CROSS=1 RUSTFLAGS="-C linker=/usr/bin/arm-linux-gnueabihf-gcc -L native=/usr/lib/arm-linux-gnueabihf" cargo build --target=armv7-unknown-linux-gnueabihf --release
}

main() {
	parse_arguments "$@"
	install_rust
}

main "$@"
