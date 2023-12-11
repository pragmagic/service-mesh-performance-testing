#! /bin/bash
parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

pkill -f "port-forward svc/fortio-service 8080:8080"

istioctl uninstall "--kubeconfig=$KUBECONFIG1" -y --purge
istioctl uninstall "--kubeconfig=$KUBECONFIG2" -y --purge

k1 delete namespace istio-system
k2 delete namespace istio-system

k1 delete ns multicluster
k2 delete ns multicluster

rm -r "$parent_path/certs"

# previous command may have failed if the setup have failed and not all resources have been deployed
true
