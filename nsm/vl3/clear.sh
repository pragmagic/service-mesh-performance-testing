#!/usr/bin/env bash

set -x

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

echo running "$0"

pkill -f "msm-perf-test-msm port-forward"

# repeat delete commands without disabling waiting
k1 delete -k "$parent_path/vl3-dns"
k1 delete -k "$parent_path/control-plane"
k1 delete ns msm-perf-test-msm
k2 delete ns msm-perf-test-msm

rm -f "$parent_path/tls.crt"
rm -f "$parent_path/tls.key"
rm -f "$parent_path/ca.crt"
rm -f "$parent_path/control-plane/control-plane.yaml"

[ ! -z "$SKIP_NSM_DEPLOY" ] || ("$parent_path/gen/interdomain/nsm/suite.gen.sh" cleanup) || exit

# previous command may have failed if the setup have failed and not all resources have been deployed
true
