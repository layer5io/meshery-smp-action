#!/usr/bin/env bash

# This script is used to deploy Istio on Kubernetes
#
# Also deploys the bookinfo application on Istio and passes the gateway URL to Meshery

# See: https://github.com/service-mesh-performance/service-mesh-performance/blob/master/protos/service_mesh.proto
export MESH_NAME='Istio'
export SERVICE_MESH='ISTIO'

# Check if mesheryctl is present, else install it
if ! [ -x "$(command -v mesheryctl)" ]; then
    echo 'mesheryctl is not installed. Installing mesheryctl client... Standby...' >&2
    curl -L https://git.io/meshery | PLATFORM=kubernetes bash -
fi

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.11.4 sh -
cd istio-1.11.4
export PATH=$PWD/bin:$PATH
istioctl install --set profile=demo -y
kubectl label namespace default istio-injection=enabled

mesheryctl app onboard -f "samples/bookinfo/platform/kube/bookinfo.yaml"

# Wait for the application to be ready
sleep 100

# Get the gateway URL and export it and
# Expose the service inside the cluster
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
export INGRESS_HOST=$(minikube ip)
export GATEWAY_URL=http://$INGRESS_HOST:$INGRESS_PORT

minikube tunnel &> /dev/null &

echo "Service Mesh: $MESH_NAME - $SERVICE_MESH"
echo "Gateway URL: $GATEWAY_URL"

echo "ENDPOINT_URL=$GATEWAY_URL/productpage" >> $GITHUB_ENV
echo "SERVICE_MESH=$SERVICE_MESH" >> $GITHUB_ENV
