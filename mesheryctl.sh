#!/usr/bin/env bash

SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")

declare -A adapters
adapters["istio"]=meshery-istio:10000
adapters["linkerd"]=meshery-linkerd:10001
adapters["consul"]=meshery-consul:10002
adapters["octarine"]=meshery-octarine:10003
adapters["network_service_mesh"]=meshery-nsm:10004
adapters["kuma"]=meshery-kuma:10007
adapters["cpx"]=meshery-cpx:10008
adapters["open_service_mesh"]=meshery-osm:10009
adapters["traefik_mesh"]=meshery-traefik-mesh:10006

main() {
	local perf_filename=
	local perf_profile_name=
	local endpoint_url=
	local service_mesh=
	local test_name=
	local load_generator=

	parse_command_line "$@"

	# perform the test given in the provided profile_id
	if [ -z "$perf_filename" ]
	then
		# get the mesh name from performance test config
		service_mesh=$(mesheryctl perf view $perf_profile_name -t ~/auth.json -o json 2>&1 | jq '."service_mesh"' | tr -d '"')

		if [[ $service_mesh != "null" ]]
		then

			shortName=$(echo ${adapters["$service_mesh"]} | cut -d '-' -f2 | cut -d ':' -f1)

			docker network connect bridge meshery_meshery_1
			docker network connect minikube meshery_meshery_1
			docker network connect bridge meshery_meshery-"$shortName"_1
			docker network connect minikube meshery_meshery-"$shortName"_1

			mesheryctl system config minikube -t ~/auth.json
		fi
		echo "Running test with performance profile $perf_profile_name"
		mesheryctl perf apply $perf_profile_name -t ~/auth.json --yes
		
	else
		for mesh in "${!adapters[@]}"
		do
			shortName=$(echo ${adapters["$mesh"]} | cut -d '-' -f2 | cut -d ':' -f1)

			docker network connect bridge meshery_meshery-"$shortName"_1
			docker network connect minikube meshery_meshery-"$shortName"_1
		done

		docker network connect bridge meshery_meshery_1
		docker network connect minikube meshery_meshery_1
		mesheryctl system config minikube -t ~/auth.json

		echo "Configuration file: $perf_filename"
		echo "Endpoint URL: $endpoint_url"
		echo "Service Mesh: $service_mesh"
		echo "Test Name: $test_name"
		echo "Load Generator: $load_generator"

		echo "Running test with test configuration file $perf_filename"
		mesheryctl perf apply --file $GITHUB_WORKSPACE/.github/$perf_filename -t ~/auth.json --url "$endpoint_url" --mesh "$service_mesh" --name "$test_name" --load-generator "$load_generator" $perf_profile_name --yes
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
					echo "ERROR: '--profile-name' cannot be empty." >&2
					exit 1
				fi
				;;
			--profile-name)
				if [[ -n "${2:-}" ]]; then
					perf_profile_name=$2
					shift
				else
					echo "ERROR: '--profile-id' cannot be empty." >&2
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
			*)
				break
				;;
		esac
		shift
	done
}

main "$@"
