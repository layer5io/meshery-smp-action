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

  	curl -L https://meshery.io/install | sudo PLATFORM=$PLATFORM bash - &

	sleep 60
}

create_k8s_cluster() {
	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
	sudo install minikube-linux-amd64 /usr/local/bin/minikube
	sudo apt update -y
	sudo apt install conntrack
	minikube version
	minikube start --driver=none --kubernetes-version=v1.20.7
	sleep 40
}

meshery_config() {
	mkdir ~/.meshery
	config='{"contexts":{"local":{"endpoint":"http://localhost:9081","token":"Default","platform":"docker","adapters":[],"channel":"stable","version":"latest"}},"current-context":"local","tokens":[{"location":"auth.json","name":"Default"}]}'

	echo $config | yq e '."contexts"."local"."adapters"[0]="'$1'"' -P - > ~/.meshery/config.yaml

	cat ~/.meshery/config.yaml
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
			#--service-mesh)
			#	if [[ -n "${2:-}" ]]; then
			#		meshery_config "meshery-$2"
			#		shift
			#	else
			#		echo "ERROR: '--service-mesh' cannot be empty." >&2
			#		exit 1
			#	fi
			#	;;
			*)
				break
				;;
		esac
		shift
	done
}

main "$@"
