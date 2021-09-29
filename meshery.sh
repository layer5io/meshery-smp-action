#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")

main() {

	local provider_token=
	local PLATFORM=docker

	parse_command_line "$@"

	echo "Checking if a k8s cluster exits..."
	if kubectl config current-context
	then
		echo "Cluster found"
	else
		printf "Cluster not found. \nCreating one...\n"
		create_k8s_cluster
		echo "Cluster created successfully!"
	fi

	if [[ -z $provider_token ]]
	then
		printf "Token not provided.\nUsing local provider...\n"
		echo '{ "meshery-provider": "None", "token": null }' | jq -c '.token = ""'> ~/auth.json
	else
		echo '{ "meshery-provider": "Meshery", "token": null }' | jq -c '.token = "'$provider_token'"' > ~/auth.json
	fi
	cat ~/auth.json

	kubectl config view --minify --flatten > ~/minified_config
	mv ~/minified_config ~/.kube/config

	curl -L https://git.io/meshery | DEPLOY_MESHERY=false bash -

	mesheryctl system context create new-context --platform $PLATFORM --url http://localhost:9081 --set --yes
	mesheryctl system channel set edge-latest

	mesheryctl system start --yes

	sleep 60
}

create_k8s_cluster() {
	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
	sudo install minikube-linux-amd64 /usr/local/bin/minikube
	sudo apt update -y
	sudo apt install conntrack
	minikube version
	wait_for_docker
	minikube start --driver=docker --kubernetes-version=v1.20.7
	sleep 40
}

wait_for_docker() {
	while :
	do
		if docker version -f '{{.Server.Version}} - {{.Client.Version}}'
		then
			break
		else
			sleep 5
		fi
	done
}

parse_command_line() {
	while :
	do
		case "${1:-}" in
			-t|--provider-token)
				if [[ -n "${2:-}" ]]; then
					provider_token=$2
					shift
				else
					echo "ERROR: '-t|--provider_token' cannot be empty." >&2
					exit 1
				fi
				;;
			-p|--platform)
				if [[ -n "${2:-}" ]]; then
					PLATFORM=$2
					shift
				else
					echo "ERROR: '-p|--platform' cannot be empty." >&2
					exit 1
				fi
				;;
			*)
				break
				;;
		esac
		shift
	done
}

main "$@"
