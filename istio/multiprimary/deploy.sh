#!/bin/bash
parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

source ./scripts/try_run.sh || exit

echo running "$0"

(
try_run_line mkdir -p "$parent_path/certs" || exit
cd "$parent_path/certs" || exit

try_run_line make -f "$parent_path/tools/certs/Makefile.selfsigned.mk" root-ca || exit

try_run_line make -f "$parent_path/tools/certs/Makefile.selfsigned.mk" cluster1-cacerts || exit
try_run_line make -f "$parent_path/tools/certs/Makefile.selfsigned.mk" cluster2-cacerts || exit
)

try_run_line k1 create namespace istio-system || exit

try_run_line k1 create secret generic cacerts -n istio-system \
      --from-file "$parent_path"/certs/cluster1/ca-key.pem \
      --from-file "$parent_path"/certs/cluster1/ca-cert.pem \
      --from-file "$parent_path"/certs/cluster1/root-cert.pem \
      --from-file "$parent_path"/certs/cluster1/cert-chain.pem || exit

try_run_line k1 label namespace istio-system topology.istio.io/network=network1 || exit

# Configure cluster1 as a primary
echo "istioctl install 1..."
istioctl install \
    --skip-confirmation \
    --readiness-timeout 1m \
    --kubeconfig="$KUBECONFIG1" \
    --force=true \
    --verify \
    -f "$parent_path/configs-k8s/cluster1.yaml" \
    || exit

try_run_line k1 get pod -A

echo "istioctl install 1: east-west gateway..."
"$parent_path/gen-eastwest-gateway.sh" \
    --mesh mesh1 \
    --cluster cluster1 \
    --network network1 |
    istioctl install \
    --readiness-timeout 1m \
    --kubeconfig="$KUBECONFIG1" \
    --skip-confirmation \
     -f - || exit
try_run_line k1 get pod -A

# TODO add proper check
try_run_line k1 get svc istio-eastwestgateway -n istio-system || exit

# Expose the control plane in cluster1
try_run_line k1 apply -n istio-system -f "$parent_path/configs-k8s/expose-istiod.yaml" || exit

# wait for loadbalancer to get ip assigned
try_run 'istio_eastwestgateway1_ip=$(k1 get services -n istio-system istio-eastwestgateway -o go-template='"'"'{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'"'"')
if [[ $istio_eastwestgateway1_ip == *"no value"* ]]; then
    istio_eastwestgateway1_ip=$(k1 get services -n istio-system istio-eastwestgateway -o go-template='"'"'{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}'"'"')
    istio_eastwestgateway1_ip=$(dig +short "$istio_eastwestgateway1_ip" | head -1) || exit
fi
# if IPv6
if [[ $istio_eastwestgateway1_ip =~ ":" ]]; then "istio_eastwestgateway1_ip=[$istio_eastwestgateway1_ip]"; fi

echo istio_eastwestgateway1_ip is "$istio_eastwestgateway1_ip"
[[ ! -z $istio_eastwestgateway1_ip ]]' || exit

try_run_line k2 create namespace istio-system || exit
try_run_line k2 annotate namespace istio-system topology.istio.io/controlPlaneClusters=cluster1 || exit
try_run_line k2 label namespace istio-system topology.istio.io/network=network2 || exit

try_run_line k2 create secret generic cacerts -n istio-system \
      --from-file "$parent_path"/certs/cluster2/ca-key.pem \
      --from-file "$parent_path"/certs/cluster2/ca-cert.pem \
      --from-file "$parent_path"/certs/cluster2/root-cert.pem \
      --from-file "$parent_path"/certs/cluster2/cert-chain.pem || exit


# Configure cluster2 as a remote
echo DISCOVERY_ADDRESS == $istio_eastwestgateway1_ip

echo "istioctl install 2..."
istioctl install \
    --skip-confirmation \
    --readiness-timeout 1m \
    --kubeconfig="$KUBECONFIG2" \
    --force=true \
    --verify \
    -f "$parent_path/configs-k8s/cluster2.yaml" \
    || exit
try_run_line k2 get pod -A

echo "istioctl install 2: east-west gateway..."
"$parent_path"/gen-eastwest-gateway.sh --mesh mesh1 --cluster cluster2 --network network2 | \
    istioctl install \
    --readiness-timeout 1m \
    --kubeconfig="$KUBECONFIG2" \
    --skip-confirmation \
    -f - || exit

# wait for loadbalancer to get ip assigned
try_run 'istio_eastwestgateway2_ip=$(k2 get services -n istio-system istio-eastwestgateway -o go-template='"'"'{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'"'"')
if [[ $istio_eastwestgateway2_ip == *"no value"* ]]; then
    istio_eastwestgateway2_ip=$(k2 get services -n istio-system istio-eastwestgateway -o go-template='"'"'{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}'"'"')
    istio_eastwestgateway2_ip=$(dig +short "$istio_eastwestgateway2_ip" | head -1) || exit
fi
# if IPv6
if [[ $istio_eastwestgateway2_ip =~ ":" ]]; then "istio_eastwestgateway2_ip=[$istio_eastwestgateway2_ip]"; fi

echo istio_eastwestgateway2_ip is "$istio_eastwestgateway2_ip"
[[ ! -z $istio_eastwestgateway2_ip ]]' || exit


try_run_line k2 get pod -A
try_run_line k2 get svc istio-eastwestgateway -n istio-system || exit

# Expose services
try_run_line k1 apply -n istio-system -f "$parent_path/configs-k8s/expose-services.yaml" || exit
try_run_line k2 apply -n istio-system -f "$parent_path/configs-k8s/expose-services.yaml" || exit


# Enable Endpoint Discovery
kind_arg=
if [ ! "$USE_KIND_NODE" = "" ]; then
    kind1_cp_ip=$(k1 get node kind-1-control-plane -o jsonpath='{.status.addresses[0].address}') || exit
    kind1_arg="--server https://$kind1_cp_ip:6443"
    kind2_cp_ip=$(k2 get node kind-2-control-plane -o jsonpath='{.status.addresses[0].address}') || exit
    kind2_arg="--server https://$kind2_cp_ip:6443"
fi
try_run_line istioctl create-remote-secret \
    --kubeconfig="$KUBECONFIG2" \
    $kind2_arg \
    --name=cluster2 '|' \
    k1 apply -f - || exit
try_run_line istioctl create-remote-secret \
    --kubeconfig="$KUBECONFIG1" \
    $kind1_arg \
    --name=cluster2 '|' \
    k2 apply -f - || exit




# Deploy test apps:
try_run_line k1 create ns multicluster || exit
try_run_line k2 create ns multicluster || exit

try_run_line k1 label ns multicluster istio-injection=enabled || exit
try_run_line k2 label ns multicluster istio-injection=enabled || exit

try_run_line k1 apply -f "$parent_path"/configs-k8s/fortio-service.yaml -n multicluster || exit
try_run_line k2 apply -f "$parent_path"/configs-k8s/fortio-service.yaml -n multicluster || exit

try_run_line k1 apply -f "$parent_path"/configs-k8s/nginx-service.yaml -n multicluster || exit
try_run_line k2 apply -f "$parent_path"/configs-k8s/nginx-service.yaml -n multicluster || exit

try_run_line k2 apply -f "$parent_path"/configs-k8s/nginx.yaml -n multicluster || exit
try_run_line k2 wait --for=condition=ready --timeout=1m pod -l app=nginx -n multicluster || exit

try_run_line k1 apply -f "$parent_path"/configs-k8s/fortio.yaml -n multicluster || exit
try_run_line k1 wait --for=condition=ready --timeout=1m pod -l app=fortio -n multicluster || exit

# open access to the test-load service on local machine
k1 -n multicluster port-forward svc/fortio-service 8080:8080 &
# it can take some time for the background job to start listening to local port
sleep 5

# you can open http://127.0.0.1:8080/fortio/ to ensure that the test-load server is working
