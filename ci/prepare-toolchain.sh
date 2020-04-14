#!/usr/bin/env bash
set -euxo pipefail

stderr() {
	cat <<< "${0}: ${@}" 1>&2
}

show_usage() {
	stderr "Usage: ${0} DOCKER_USERNAME DOCKER_PASSWORD TARGET_PLATFORM [DIST]"
	stderr 'Builds a docker image for compiling the hunter file manager.'
	stderr '   DOCKER_USERNAME: Username of your docker hub account'
	stderr '   DOCKER_PASSWORD: Password of your docker hub account'
	stderr '   TARGET_PLATFORM: Platform triple; see "rustc --print target-list"'
	stderr '              DIST: Name of the Ubuntu release version to use'
	if [[ -n "${1}" ]]; then
		stderr
		stderr "$@"
	fi
	exit 1
}

main() {
	# Check if required parameters are set
	if [[ -z "${1}" ]]; then
		show_usage 'Error: Missing required parameter "DOCKER_USERNAME"'
	elif [[ -z "${2}" ]]; then
		show_usage 'Error: Missing required parameter "DOCKER_PASSWORD"'
	elif [[ -z "${3}" ]]; then
		show_usage 'Error: Missing required parameter "TARGET_PLATFORM"'
	fi

	# Validate parameters
	local user="${1}"
	local pass="${2}"
	local platform="${3}"
	local arch=''
	local dist="${4:-focal}"
	local libs=''
	case "${platform}" in
		armv7-unknown-linux-gnueabihf)
			arch='armhf'
			libs='arm-linux-gnueabihf'
			;;
		aarch64-unknown-linux-gnu)
			arch='arm64'
			libs='aarch64-linux-gnu'
			;;
		i686-unknown-linux-gnu)
			arch='i386'
			dist='eoan'
			libs='i386-linux-gnu'
			;;
		x86_64-unknown-linux-gnu)
			arch='amd64'
			libs='x86_64-linux-gnu'
			;;
    powerpc64le-unknown-linux-gnu)
			arch='ppc64el'
			libs='powerpc64le-linux-gnu'
			;;
    s390x-unknown-linux-gnu)
			arch='s390x'
			libs='s390x-linux-gnu'
			;;
		x86_64-apple-darwin)
			brew install \
				gst-editing-services \
				gst-libav \
				gst-plugins-bad \
				gst-plugins-base \
				gst-plugins-good \
				gst-plugins-ugly \
				gstreamer \
				gst-rtsp-server || true
			stderr 'Platform can now be compiled on the native system.'
			exit 0
			;;
		*)
			show_usage "Target platform \"${platform}\" is not supported."
			;;
	esac

	# Bypass rebuilding the image if it already exists on docker hub
	local img="cross-${platform}"
	local tag="$(cross --version | grep 'cross ' | cut --characters=7-)"
	if curl --location --silent --fail \
		"https://hub.docker.com/v1/repositories/${user}/${img}/tags/${tag}" \
		>/dev/null
	then
		stderr 'Image already exists on docker hub.'
		exit 0
	fi

	# Check if a base image for our cross version exists
	local base_img
	if curl --location --silent --fail \
		"https://hub.docker.com/v1/repositories/rustembedded/cross/tags/${platform}-${tag}" \
		>/dev/null
	then
		base_img="rustembedded/cross:${platform}-${tag}"
	else
	  base_img="rustembedded/cross:${platform}"
	fi

	# Login to docker hub now to ensure that the built image can be pushed
	echo "${pass}" | docker login --username "${user}" --password-stdin

	# Build the docker image using the dynamically generated Dockerfile
	local self_dir="$(dirname $(realpath --no-symlinks ${0}))"
	docker build "${self_dir}" \
		--tag "${user}/${img}:${tag}" \
		--tag "${user}/${img}:latest" \
		--file - <<-EOF
		FROM "${base_img}"
		COPY prepare-image.sh /tmp/
		RUN /tmp/prepare-image.sh "${arch}" "${dist}"
		ENV \
			PKG_CONFIG_ALLOW_CROSS="1" \
			PKG_CONFIG_PATH="/usr/lib/${libs}/pkgconfig"
	EOF

	# Push the built image to docker hub and tag it as the latest build
	docker push "${user}/${img}:${tag}"
	docker push "${user}/${img}:latest"

	# Try to logout from the docker hub
	docker logout || true

	stderr "Platform can now be compiled in the prepared docker image."
}

main "$@"
