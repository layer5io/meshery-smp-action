#!/usr/bin/env bash

# This script is used to deploy Open Service Mesh on Kubernetes
#
# Also deploys Bookstore application on OSM

# See: https://github.com/service-mesh-performance/service-mesh-performance/blob/master/protos/service_mesh.proto
export MESH_NAME='Open Service Mesh'
export SERVICE_MESH='OPEN_SERVICE_MESH'

# Check if mesheryctl is present, else install it
if ! [ -x "$(command -v mesheryctl)" ]; then
    kubectl config view --minify --flatten > ~/minified_config
	mv ~/minified_config ~/.kube/config
    echo 'mesheryctl is not installed. Installing mesheryctl client... Standby... (Starting Meshery as well...)' >&2
    curl -L https://meshery.io/install  | ADAPTERS=osm PLATFORM=kubernetes bash -
fi

curl -fsL https://raw.githubusercontent.com/openservicemesh/osm-docs/main/manifests/apps/bookstore.yaml --output bookstore.yaml

sleep 200 
#mesheryctl system login --provider None
echo "Meshery has been installed."
kubectl get pods -n meshery

echo "Deploying meshery osm adapter..."
echo | mesheryctl mesh deploy adapter meshery-osm:10009 --token "./.github/workflows/auth.json"
sleep 200
echo "Onboarding application... Standby for few minutes..."
#mesheryctl app onboard -f "./bookstore.yaml" -s "Kubernetes Manifest" --token "./.github/workflows/auth.json"
mesheryctl pattern apply -f "https://raw.githubusercontent.com/openservicemesh/osm-docs/main/manifests/apps/bookstore.yaml" --token "./.github/workflows/auth.json"

# Wait for the application to be ready
sleep 100

kubectl get deployments -n bookstore
kubectl get pods -n bookstore

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
