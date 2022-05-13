#!/usr/bin/env bash
# This script is used to deploy Istio on Kubernetes
#
# Also deploys the bookinfo application on Istio and passes the gateway URL to Meshery
# See: https://github.com/service-mesh-performance/service-mesh-performance/blob/master/protos/service_mesh.proto

export MESH_NAME='Consul'
export SERVICE_MESH='CONSUL'

# Check if mesheryctl is present, else install it and deploy Kuma adapter
if ! [ -x "$(command -v mesheryctl)" ]; then
    echo 'mesheryctl is not installed. Installing mesheryctl client... Standby... (Starting Meshery as well...)' >&2
    curl -L https://meshery.io/install | ADAPTERS=consul PLATFORM=kubernetes bash -
fi

sleep 10

# TODO: Didn't find a demo apps on Consule, so use bookinfo app.
mesheryctl app onboard -f "https://raw.githubusercontent.com/istio/istio/blob/master/samples/bookinfo/platform/kube/bookinfo.yaml"

echo "Service Mesh: $MESH_NAME - $SERVICE_MESH"
echo "Endpoint URL: http://localhost:5000"

# Pass the endpoint to be used by Meshery
echo "ENDPOINT_URL=http://localhost:5000" >> $GITHUB_ENV
echo "SERVICE_MESH=$SERVICE_MESH" >> $GITHUB_ENV