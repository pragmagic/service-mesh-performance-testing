#!/bin/bash

set -x

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

echo running "$0"

pkill -f "msm-perf-test-mz port-forward"

pkill -f "port-forward svc/kuma-control-plane 5681:5681"

k1 delete ns msm-perf-test-mz
k2 delete ns msm-perf-test-mz
k1 delete -k "$parent_path/configs-k8s/c1/zone/"
k2 delete -k "$parent_path/configs-k8s/c2/zone/"
k1 delete ns kuma-system
k2 delete ns kuma-system
k1 delete -f "$parent_path/configs-k8s/c1/kuma-global-cp-universal.yaml"

# previous command may have failed if the setup have failed and not all resources have been deployed
true
