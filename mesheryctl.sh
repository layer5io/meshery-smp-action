#!/usr/bin/env bash

SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")

declare -A adapters
adapters["istio"]=meshery-istio:10000
adapters["linkerd"]=meshery-linkerd:10001
adapters["consul"]=meshery-consul:10002
adapters["octarine"]=meshery-octarine:10003
adapters["nsm"]=meshery-nsm:10004
adapters["kuma"]=meshery-kuma:10007
adapters["cpx"]=meshery-cpx:10008
adapters["osm"]=meshery-osm:10009
adapters["traefik-mesh"]=meshery-traefik-mesh:10006

main() {
	#local service_mesh_adapter=
	#local service_mesh=
	local perf_profile_name=
	local perf_profile_id=

	parse_command_line "$@"
	#docker network connect bridge meshery_meshery_1
	#docker network connect minikube meshery_meshery_1
	#docker network connect minikube meshery_meshery-"$service_mesh"_1
	#docker network connect bridge meshery_meshery-"$service_mesh"_1

	mesheryctl system config minikube -t ~/auth.json
	#echo $spec $service_mesh_adapter

	if [ -z "$perf_profile_id" ]
	then
		#TODO: deploy service mesh once we have SSE client in mesh deploy
		#mesheryctl perf view $perf_profile_id -t ~/auth.json -o json
		mesheryctl perf apply $perf_profile_id -t ~/Downloads/auth.json
	else
		mesheryctl perf apply --file $GITHUB_WORKSPACE/.github/$perf_profile_name -t ~/auth.json
	fi
}

parse_command_line() {
	while :
	do
		case "${1:-}" in
			--profile-name)
				if [[ -n "${2:-}" ]]; then
					perf_profile_name=$2
					shift
				else
					echo "ERROR: '--profile-name' cannot be empty." >&2
					exit 1
				fi
				;;
			--profile-id)
				if [[ -n "${2:-}" ]]; then
					perf_profile_id=$2
					shift
				else
					echo "ERROR: '--profile-id' cannot be empty." >&2
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
