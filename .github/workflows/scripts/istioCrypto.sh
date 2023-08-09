#!/usr/bin/env bash


# Istio, crypto deployment

export MESH_NAME='Istio'
export SERVICE_MESH='ISTIO'

kubectl get pods -n meshery

echo "Meshery has been installed."
# mesheryctl system login --provider None

# mesheryctl mesh deploy istio --watch

sleep 200


# so that istio operator gets initialized

# Applying/deploying crpyto pattern
echo "Applying IstioCrypto Design"
mesheryctl pattern apply -f ./.github/workflows/CryptoMB-design.yaml --token "./.github/workflows/auth.json"

sleep 200

kubectl get all -n istio-operator

# deplyoing httbin application
echo "OnBoarding HTTP Design"
mesheryctl app onboard -f  ../httpbin.yaml -s "Kubernetes Manifest" --token "./.github/workflows/auth.json"

sleep 100

export INGRESS_NAME=istio-ingressgateway
export INGRESS_NS=istio-system

kubectl get svc "$INGRESS_NAME" -n "$INGRESS_NS"


export INGRESS_HOST=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export SECURE_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
export TCP_INGRESS_PORT=$(kubectl -n "$INGRESS_NS" get service "$INGRESS_NAME" -o jsonpath='{.spec.ports[?(@.name=="tcp")].port}')


export GATEWAY_URL=http://$INGRESS_HOST:$INGRESS_PORT/headers

# mesheryctl perf apply --file $GITHUB_WORKSPACE/.github/$perf_filename -t ~/auth.json --url "$endpoint_url" --mesh "$service_mesh" --name "$test_name" --load-generator "$load_generator" $perf_profile_name -y

echo "Service Mesh: $MESH_NAME - $SERVICE_MESH"
echo "Gateway URL: $GATEWAY_URL"
echo "ENDPOINT_URL=$GATEWAY_URL >> $GITHUB_ENV
echo "SERVICE_MESH=$SERVICE_MESH" >> $GITHUB_ENV