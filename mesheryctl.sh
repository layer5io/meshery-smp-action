#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")

declare -A adapters
adapters["istio"]=meshery-istio:10000
adapters["linkerd"]=meshery-linkerd:10001
adapters["consul"]=meshery-consul:10002
adapters["octarine"]=meshery-octarine:10003
adapters["nsm"]=meshery-nsm:10004
adapters["network_service_mesh"]=meshery-nsm:10004
adapters["kuma"]=meshery-kuma:10007
adapters["cpx"]=meshery-cpx:10008
adapters["osm"]=meshery-osm:10009
adapters["open_service_mesh"]=meshery-osm:10009
adapters["traefik-mesh"]=meshery-traefik-mesh:10006
adapters["traefik_mesh"]=meshery-traefik-mesh:10006

main() {
	local perf_filename=
	local perf_profile_name=
	local endpoint_url=
	local service_mesh=
	local test_name=
	local load_generator=
	local mesh_deployed=
	local PLATFORM=docker

	# load balancer
	minikube tunnel &> /dev/null &
	sleep 10

	parse_command_line "$@"

	# perform the test given in the provided profile_id
	if [ -z "$perf_profile_name" ]
	then

		# connect containers and deploy service mesh
		if [[ $PLATFORM == "docker" ]]
		then
			shortName=$(echo ${adapters["$service_mesh"]} | cut -d '-' -f2 | cut -d ':' -f1)
			docker_networking "$shortName"
		fi

		if [[ $mesh_deployed != "true" ]]
		then
			deploy_mesh "$service_mesh" "$PLATFORM"
		fi

		kubectl get pods --all-namespaces

		echo "Configuration file: $perf_filename"
		echo "Endpoint URL: $endpoint_url"
		echo "Service Mesh: $service_mesh"
		echo "Test Name: $test_name"
		echo "Load Generator: $load_generator"

		mesheryctl perf apply --file $GITHUB_WORKSPACE/.github/$perf_filename -t ~/auth.json --url "$endpoint_url" --mesh "$service_mesh" --name "$test_name" --load-generator "$load_generator" test-profile

	# perform test given in ID specified by perf_profile_name
	else

		# get the mesh name from performance test config
		echo "Using $perf_profile_name..."
		mesheryctl perf profile $perf_profile_name -t ~/auth.json -o yaml
		service_mesh=$(mesheryctl perf profile $perf_profile_name -t ~/auth.json -o json 2>&1 | jq '."service_mesh"' | tr -d '"')

		if [[ $service_mesh != "null" ]]
		then
			shortName=$(echo ${adapters["$service_mesh"]} | cut -d '-' -f2 | cut -d ':' -f1)
			if [[ $PLATFORM == "docker" ]]
			then
				docker_networking "$shortName"
			fi
			if [[ $mesh_deployed != "true" ]]
			then
				deploy_mesh "$service_mesh" "$PLATFORM"
			fi
		fi

		kubectl get pods --all-namespaces
		echo "Configuration file: $perf_profile_name"
		echo "Endpoint URL: $endpoint_url"
		echo "Service Mesh: $service_mesh"
		echo "Test Name: $test_name"
		echo "Load Generator: $load_generator"

		# apply performance test given in named profile
		mesheryctl perf apply $perf_profile_name -t ~/auth.json

	fi
}

parse_command_line() {
	while :
	do
		case "${1:-}" in
			--perf-filename)
				if [[ -n "${2:-}" ]]; then
					perf_filename=$2
					shift
				else
					echo "ERROR: '--profile-filename' cannot be empty." >&2
					exit 1
				fi
				;;
			--profile-name)
				if [[ -n "${2:-}" ]]; then
					perf_profile_name=$2
					shift
				else
					echo "ERROR: '--profile-name' cannot be empty." >&2
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
			--endpoint-url)
				if [[ -n "${2:-}" ]]; then
					endpoint_url=$2
					shift
				else
					echo "ERROR: '--endpoint-url' cannot be empty." >&2
					exit 1
				fi
				;;
			--service-mesh)
				if [[ -n "${2:-}" ]]; then
					service_mesh=$2
					shift
				else
					echo "ERROR: '--service-mesh' cannot be empty." >&2
					exit 1
				fi
				;;
			--test-name)
				if [[ -n "${2:-}" ]]; then
					test_name=$2
					shift
				else
					echo "ERROR: '--test-name' cannot be empty." >&2
					exit 1
				fi
				;;
			--load-generator)
				if [[ -n "${2:-}" ]]; then
					load_generator=$2
					shift
				else
					echo "ERROR: '--load-generator' cannot be empty." >&2
					exit 1
				fi
				;;
			--mesh-deployed)
				if [[ -n "${2:-}" ]]; then
					mesh_deployed=$2
					shift
				else
					echo "ERROR: '--mesh-deployed' cannot be empty." >&2
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

docker_networking() {
		docker network connect bridge meshery_meshery-"$1"_1
		docker network connect minikube meshery_meshery-"$1"_1

		docker network connect bridge meshery_meshery_1
		docker network connect minikube meshery_meshery_1
		mesheryctl system config minikube -t ~/auth.json

		docker ps
}

deploy_mesh() {
	if [[ $2 == "docker" ]]
	then
		echo "deploying service mesh..."
		mesheryctl mesh deploy --adapter ${adapters["$1"]} -t ~/auth.json "$1" --watch
		sleep 40
	else
		# --watch flag doesn't work for in cluster deployments
		echo "deploying service mesh..."
		mesheryctl mesh deploy --adapter ${adapters["$1"]} -t ~/auth.json "$1"
		echo "checking on $service_mesh deployments..."
		sleep 40
	fi
}

main "$@"
