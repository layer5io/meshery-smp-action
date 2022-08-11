#!/usr/bin/env bash

# This script is used to deploy Linkerd on Kubernetes
#
# Also deploys EmojiVoto on Linkerd and exposes the service to Meshery

# See: https://github.com/service-mesh-performance/service-mesh-performance/blob/master/protos/service_mesh.proto
export MESH_NAME='Linkerd'
export SERVICE_MESH='LINKERD'

# Check if mesheryctl is present, else install it
if ! [ -x "$(command -v mesheryctl)" ]; then
    echo 'mesheryctl is not installed. Installing mesheryctl client... Standby... (Starting Meshery as well...)' >&2
    curl -L https://meshery.io/install | ADAPTERS=linkerd PLATFORM=kubernetes bash -
fi

curl -fsL https://run.linkerd.io/emojivoto.yml --output emojivoto.yml
sleep 10
#mesheryctl system login --provider None
echo | mesheryctl mesh deploy adapter meshery-linkerd:10001 --token "./.github/workflows/auth.json"
echo "Onboarding application... Standby for few minutes..."
mesheryctl app onboard -f "./emojivoto.yml" -t "./.github/workflows/auth.json"
#mesheryctl pattern apply -f "./emojivoto.yml" 

# Wait for the application to be ready
sleep 100

echo "Service Mesh: $MESH_NAME - $SERVICE_MESH"
echo "Endpoint URL: http://localhost:8080"

# Pass the endpoint to be used by Meshery
echo "ENDPOINT_URL=http://localhost:8080" >> $GITHUB_ENV
echo "SERVICE_MESH=$SERVICE_MESH" >> $GITHUB_ENV
