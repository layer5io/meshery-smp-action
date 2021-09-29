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

	"$SCRIPT_DIR/meshery.sh" "${setupArgs[@]}"

	commandArgs=()
	if [[ -n "${INPUT_PROFILE_FILENAME:-}" ]]; then
		commandArgs=(--perf-filename ${INPUT_PROFILE_FILENAME})
	fi

	if [[ -n "${INPUT_PROFILE_NAME:-}" ]]; then
		commandArgs=(--profile-name ${INPUT_PROFILE_NAME})
	fi

	if [[ -n "${INPUT_PLATFORM:-}" ]]; then
		commandArgs+=(--platform ${INPUT_PLATFORM})
	fi

	"$SCRIPT_DIR/mesheryctl.sh" "${commandArgs[@]}"
}

main
