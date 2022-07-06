#!/usr/bin/env bash
# This script is used to deploy Istio on Kubernetes
#
# Also deploys the bookinfo application on Istio and passes the gateway URL to Meshery
# See: https://github.com/service-mesh-performance/service-mesh-performance/blob/master/protos/service_mesh.proto

export MESH_NAME='Kuma'
export SERVICE_MESH='Kuma'

# Check if mesheryctl is present, else install it and deploy Kuma adapter
if ! [ -x "$(command -v mesheryctl)" ]; then
    echo 'mesheryctl is not installed. Installing mesheryctl client... Standby... (Starting Meshery as well...)' >&2
    curl -L https://meshery.io/install | ADAPTERS=kuma PLATFORM=kubernetes bash -
fi

sleep 10

echo 'E' | mesheryctl mesh deploy adapter meshery-kuma:10000 --token "./.github/workflows/auth.json"
sleep 50
echo "Deploying demo application on Kuma..."
# Refer to https://kuma.io/docs/1.6.x/quickstart/kubernetes/#set-up-and-run
git clone https://github.com/kumahq/kuma-counter-demo.git && cd kuma-counter-demo
kubectl apply -f demo.yaml
echo "Waiting for the application to be ready..."
sleep 50
kubectl port-forward svc/demo-app -n kuma-demo 5000:5000 &

echo "Service Mesh: $MESH_NAME - $SERVICE_MESH"
echo "Endpoint URL: http://localhost:5000"

# Pass the endpoint to be used by Meshery
echo "ENDPOINT_URL=http://localhost:5000" >> $GITHUB_ENV
echo "SERVICE_MESH=$SERVICE_MESH" >> $GITHUB_ENV