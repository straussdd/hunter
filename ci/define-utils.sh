#!/usr/bin/env bash
set -euo pipefail

stderr() {
	cat <<< "$@" 1>&2
}
