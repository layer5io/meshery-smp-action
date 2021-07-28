#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")

main() {
	setupArgs=()
	if [[ -n "${INPUT_PROVIDER_TOKEN:-}" ]]; then
		setupArgs+=(--provider-token ${INPUT_PROVIDER_TOKEN})
	fi

	if [[ -n "${INPUT_PLATFORM:-}" ]]; then
		setupArgs+=(--platform ${INPUT_PLATFORM})
	fi

	if [[ -n "${INPUT_SERVICE_MESH:-}" ]]; then
		setupArgs+=(--service-mesh ${INPUT_SERVICE_MESH})
	fi

	"$SCRIPT_DIR/meshery.sh" "${setupArgs[@]}"

	commandArgs=()
	if [[ -n "${INPUT_SPEC:-}" ]]; then
		commandArgs+=(--spec ${INPUT_SPEC})
	fi

	if [[ -n "${INPUT_SERVICE_MESH:-}" ]]; then
		commandArgs+=(--service-mesh ${INPUT_SERVICE_MESH})
	fi

	if [[ -n "${INPUT_PROFILE_FILE_NAME:-}" ]]; then
		commandArgs+=(--profile-name ${INPUT_PROFILE_FILE_NAME})
	fi

	"$SCRIPT_DIR/mesheryctl.sh" "${commandArgs[@]}"
}

main
