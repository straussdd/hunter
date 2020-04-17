#!/usr/bin/env bash
set -euo pipefail

declare -r -a PKG_ARCHS=(
	'amd64'
	'arm64'
	'armel'
	'armhf'
	'i386'
	'mips64el'
	'mipsel'
	'ppc64el'
	's390x'
)

declare -r -A ARCH_GCC=(
	['amd64']='gcc:amd64'
	['arm64']='gcc-aarch64-linux-gnu:amd64'
	['armel']='gcc-arm-linux-gnueabi:amd64'
	['armhf']='gcc-arm-linux-gnueabihf:amd64'
	['i386']='gcc-i686-linux-gnu:amd64'
	['mips64el']='gcc-mips64el-linux-gnuabi64:amd64'
	['mipsel']='gcc-mipsel-linux-gnu:amd64'
	['ppc64el']='gcc-powerpc64le-linux-gnu:amd64'
	['s390x']='gcc-s390x-linux-gnu:amd64'
)

declare -r -A ARCH_LIBC=(
	['amd64']='libc6-dev:amd64'
	['arm64']='libc6-dev-arm64-cross:amd64'
	['armel']='libc6-dev-armel-cross:amd64'
	['armhf']='libc6-dev-armhf-cross:amd64'
	['i386']='libc6-dev-i386-cross:amd64'
	['mips64el']='libc6-dev-mips64el-cross:amd64'
	['mipsel']='libc6-dev-mipsel-cross:amd64'
	['ppc64el']='libc6-dev-ppc64el-cross:amd64'
	['s390x']='libc6-dev-s390x-cross:amd64'
)

declare -r -A ARCH_TUPLE=(
	['amd64']='x86_64-linux-gnu'
	['arm64']='aarch64-linux-gnu'
	['armel']='arm-linux-gnueabi'
	['armhf']='arm-linux-gnueabihf'
	['i386']='i386-linux-gnu'
	['mips64el']='mips64el-linux-gnuabi64'
	['mipsel']='mipsel-linux-gnu'
	['ppc64el']='powerpc64le-linux-gnu'
	['s390x']='s390x-linux-gnu'
)

declare -r -A ARCH_TUPLE_LONG=(
	['amd64']='x86_64-unknown-linux-gnu'
	['arm64']='aarch64-unknown-linux-gnu'
	['armel']='arm-unknown-linux-gnueabi'
	['armhf']='armv7-unknown-linux-gnueabihf'
	['i386']='i686-unknown-linux-gnu'
	['mips64el']='mips64el-unknown-linux-gnuabi64'
	['mipsel']='mipsel-unknown-linux-gnu'
	['ppc64el']='powerpc64le-unknown-linux-gnu'
	['s390x']='s390x-unknown-linux-gnu'
)
