#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")

main() {
	get_dependencies

	setupArgs=()
	if [[ -n "${INPUT_PROVIDER_TOKEN:-}" ]]; then
		setupArgs+=(--provider-token ${INPUT_PROVIDER_TOKEN})
	fi

	if [[ -n "${INPUT_PLATFORM:-}" ]]; then
		setupArgs+=(--platform ${INPUT_PLATFORM})
	fi

	bash "$SCRIPT_DIR/meshery.sh" "${setupArgs[@]}"

	commandArgs=()
	if [[ -n "${INPUT_PROFILE_FILENAME:-}" ]]; then
		commandArgs=(--perf-filename ${INPUT_PROFILE_FILENAME})
	fi

	if [[ -n "${INPUT_PROFILE_NAME:-}" ]]; then
		commandArgs=(--profile-name ${INPUT_PROFILE_NAME})
	fi

	if [[ -n "${INPUT_ENDPOINT_URL:-}" ]]; then
		commandArgs+=(--endpoint-url ${INPUT_ENDPOINT_URL})
	fi

	bash "$SCRIPT_DIR/mesheryctl.sh" "${commandArgs[@]}"
}

get_dependencies() {
	sudo wget https://github.com/mikefarah/yq/releases/download/v4.10.0/yq_linux_amd64 -O /usr/bin/yq --quiet
	sudo chmod +x /usr/bin/yq
}

main
