#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

replica_count=${1:-1}
port_file=$2

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

source ./scripts/try_run.sh || exit

echo running "$0"

try_run_line k1 apply -f "$parent_path/configs-k8s/c1/kuma-global-cp-universal.yaml" || exit

try_run_line k1 wait -n kuma-global-cp --for condition=ready --timeout=1m pod -l app=kuma-control-plane || exit

# Install zone control planes:
try_run_line kumactl install control-plane \
    --without-kubernetes-connection \
    --set controlPlane.mode=zone \
    --set controlPlane.zone=zone1 \
    --set ingress.enabled=true \
    --set controlPlane.kdsGlobalAddress=grpcs://kuma-global-zone-sync.kuma-global-cp:5685 \
    --set controlPlane.tls.kdsZoneClient.skipVerify=true \
    '>' "$parent_path/configs-k8s/c1/zone/kuma-zone-install.yaml" || exit
try_run_line k1 apply -k "$parent_path/configs-k8s/c1/zone/" || exit

try_run 'kuma_global_cp_ip=$(k1 get services -n kuma-global-cp kuma-global-zone-sync -o go-template='"'"'{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'"'"')
if [[ $kuma_global_cp_ip == *"no value"* ]]; then
    kuma_global_cp_ip=$(k1 get services -n kuma-global-cp kuma-global-zone-sync -o go-template='"'"'{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}'"'"')
    kuma_global_cp_ip=$(dig +short "$kuma_global_cp_ip" | head -1) || exit
fi
# if IPv6
if [[ $kuma_global_cp_ip =~ ":" ]]; then "kuma_global_cp_ip=[$kuma_global_cp_ip]"; fi

echo kuma_global_cp_ip is "$kuma_global_cp_ip"
[[ ! -z $kuma_global_cp_ip ]]' || exit

# ip1=$(kubectl --kubeconfig=$KUBECONFIG1 get node -o go-template='{{ $addresses := (index .items 0).status.addresses }}{{range $addresses}}{{if eq .type "ExternalIP"}}{{.address}}{{break}}{{end}}{{end}}')
# if [ -z "$ip1" ]; then
#   ip1=$(kubectl --kubeconfig=$KUBECONFIG1 get node -o go-template='{{ $addresses := (index .items 0).status.addresses }}{{range $addresses}}{{if eq .type "InternalIP"}}{{.address}}{{break}}{{end}}{{end}}')
# fi

# echo cluster 1 ip: $ip1
# kuma_global_cp_ip=$ip1

try_run_line kumactl install control-plane \
    --without-kubernetes-connection \
    --set controlPlane.mode=zone \
    --set controlPlane.zone=zone2 \
    --set ingress.enabled=true \
    --set controlPlane.kdsGlobalAddress="grpcs://$kuma_global_cp_ip:5685" \
    --set controlPlane.tls.kdsZoneClient.skipVerify=true \
    '>' "$parent_path/configs-k8s/c2/zone/kuma-zone-install.yaml" || exit
try_run_line k2 apply -k "$parent_path/configs-k8s/c2/zone/" || exit

try_run_line k1 wait -n kuma-system --for=condition=ready --timeout=1m pod -l app=kuma-control-plane || exit
try_run_line k2 wait -n kuma-system --for=condition=ready --timeout=1m pod -l app=kuma-control-plane || exit

# Enable mTLS (required for cross-zone connectivity):
k1 -n kuma-global-cp port-forward svc/kuma-control-plane 5681:5681 &
KUBECONFIG=$KUBECONFIG1 try_run_line kumactl apply -f "$parent_path/configs-k8s/c1/mesh-universal.yaml" || exit
try_run_line pkill -f "port-forward svc/kuma-control-plane 5681:5681" || exit

# Deploy test apps:
try_run_line k1 apply -f "$parent_path/configs-k8s/c1/namespace.yaml" || exit
try_run_line k1 apply -n msm-perf-test-mz -f "$parent_path/configs-k8s/c1/nginx.yaml" || exit

try_run_line k2 create ns msm-perf-test-mz
try_run_line k2 label ns msm-perf-test-mz kuma.io/sidecar-injection=enabled
try_run_line k2 -n msm-perf-test-mz apply -f "$parent_path/configs-k8s/c2/fortio.yaml" || exit
try_run_line k2 -n msm-perf-test-mz scale --replicas="$replica_count" deployment/fortio

try_run_line k1 -n msm-perf-test-mz wait --for=condition=ready --timeout=1m pod -l app=nginx || exit
try_run_line k2 -n msm-perf-test-mz wait --for=condition=ready --timeout=1m pod -l app=fortio || exit

"$parent_path"/port-forward-fortio.sh 8080 "$port_file"
