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

	parse_command_line "$@"
	#docker network connect bridge meshery_meshery_1
	#docker network connect minikube meshery_meshery_1
	#docker network connect minikube meshery_meshery-"$service_mesh"_1
	#docker network connect bridge meshery_meshery-"$service_mesh"_1

	~/mesheryctl system config minikube -t ~/auth.json
	#echo $spec $service_mesh_adapter

	mesheryctl perf apply --file $GITHUB_WORKSPACE/.github/$perf_profile_name -t ~/auth.json
}

parse_command_line() {
	while :
	do
		case "${1:-}" in
			#--service-mesh)
			#	if [[ -n "${2:-}" ]]; then
			#		# figure out assigning port numbers and adapter names
			#		service_mesh=$2
			#		service_mesh_adapter=${adapters["$2"]}
			#		shift
			#	else
			#		echo "ERROR: '--service-mesh' cannot be empty." >&2
			#		exit 1
			#	fi
			#	;;
			--profile-name)
				if [[ -n "${2:-}" ]]; then
					perf_profile_name=$2
					shift
				else
					echo "ERROR: '--profile-name' cannot be empty." >&2
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
