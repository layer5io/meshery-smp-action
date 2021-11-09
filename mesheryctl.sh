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

	parse_command_line "$@"

	# perform the test given in the provided profile_id
	if [ -z "$perf_profile_name" ]
	then
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

		mesheryctl perf apply --file $GITHUB_WORKSPACE/.github/$perf_filename -t ~/auth.json --url "$endpoint_url"

	else

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
			*)
				break
				;;
		esac
		shift
	done
}

main "$@"
