#!/usr/bin/env bash

# This script is used to deploy Open Service Mesh on Kubernetes
#
# Also deploys Bookstore application on OSM

# See: https://github.com/service-mesh-performance/service-mesh-performance/blob/master/protos/service_mesh.proto
export MESH_NAME='Open Service Mesh'
export SERVICE_MESH='OPEN_SERVICE_MESH'

# Check if mesheryctl is present, else install it
if ! [ -x "$(command -v mesheryctl)" ]; then
    echo 'mesheryctl is not installed. Installing mesheryctl client... Standby... (Starting Meshery as well...)' >&2
    curl -L https://meshery.io/install  | PLATFORM=kubernetes bash -
fi

sleep 10
mesheryctl system login --provider None
mesheryctl mesh deploy adapter meshery-osm:10009
echo "Onboarding application... Standby for few minutes..."
mesheryctl app onboard -f "https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.0/manifests/apps/bookstore.yaml"

sleep 100

kubectl get deployments -n bookstore
kubectl get pods -n bookstore

# Wait for the application to be ready
sleep 100

# Expose the application outside the cluster
# backend="$1"
# thisScript="$(dirname "$0")/$(basename "$0")"

# if [ -z "$backend" ]; then
#     echo "Usage: $thisScript <backend-name>"
#     exit 1
# fi
# hardcode bookstore comment out uneceserry code
POD="$(kubectl get pods --selector app="bookstore" -n "$BOOKSTORE_NAMESPACE" --no-headers | grep 'Running' | awk 'NR==1{print $1}')"
kubectl port-forward "$POD" -n "$BOOKSTORE_NAMESPACE" 15000:15000 &> /dev/null &

echo "Service Mesh: $MESH_NAME - $SERVICE_MESH"
echo "Endpoint URL: http://localhost:15000"

# Pass the endpoint to be used by Meshery
echo "ENDPOINT_URL=http://localhost:15000" >> $GITHUB_ENV
echo "SERVICE_MESH=$SERVICE_MESH" >> $GITHUB_ENV
