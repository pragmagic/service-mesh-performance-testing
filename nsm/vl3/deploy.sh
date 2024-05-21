#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

replica_count=${1:-1}
port_file=$2

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

source ./scripts/try_run.sh || exit

echo running "$0"

[ ! -z "$SKIP_NSM_DEPLOY" ] || ("$parent_path/gen/interdomain/nsm/suite.gen.sh" setup) || exit

# k1 -n nsm-system create configmap fwd-vpp-conf --from-file="$parent_path"/nsm/vpp.conf
try_run_line k1 -n nsm-system patch daemonsets.apps forwarder-vpp --patch-file "$parent_path"/nsm/forwarder-patch.yaml || exit
# k2 -n nsm-system create configmap fwd-vpp-conf --from-file="$parent_path"/nsm/vpp.conf
try_run_line k2 -n nsm-system patch daemonsets.apps forwarder-vpp --patch-file "$parent_path"/nsm/forwarder-patch.yaml || exit

try_run_line k1 -n nsm-system patch daemonsets.apps nsmgr --patch-file "$parent_path"/nsm/patch-nsmgr.yaml || exit
try_run_line k2 -n nsm-system patch daemonsets.apps nsmgr --patch-file "$parent_path"/nsm/patch-nsmgr.yaml || exit

function patch_nsm_deployment() {
    name=$1

    # try_run_line k1 -n nsm-system scale --replicas=0 deployment/"$name" || exit
    try_run_line k1 -n nsm-system patch deployment/"$name" --patch-file "$parent_path"/nsm/patch-"$name".yaml || exit
    # try_run_line k1 -n nsm-system scale --replicas=1 deployment/"$name" || exit

    # try_run_line k2 -n nsm-system scale --replicas=0 deployment/"$name" || exit
    try_run_line k2 -n nsm-system patch deployment/"$name" --patch-file "$parent_path"/nsm/patch-"$name".yaml || exit
    # try_run_line k2 -n nsm-system scale --replicas=1 deployment/"$name" || exit
}

patch_nsm_deployment nsmgr-proxy || exit
patch_nsm_deployment registry-k8s || exit
patch_nsm_deployment registry-proxy || exit

try_run_line k1 -n nsm-system wait --for condition=ready pod --all --timeout=1m
try_run_line k2 -n nsm-system wait --for condition=ready pod --all --timeout=1m

# Start vl3 NSE
try_run_line k1 create ns ns-dns-vl3
try_run_line k1 -n ns-dns-vl3 create configmap vl3-vpp-conf --from-file="$parent_path"/vl3-dns/vpp.conf
try_run_line k1 apply -k "$parent_path/vl3-dns" || exit

try_run_line k1 -n ns-dns-vl3 wait --for=condition=ready --timeout=1m pod -l app=vl3-ipam || exit
try_run_line k1 -n ns-dns-vl3 wait --for=condition=ready --timeout=1m pod -l app=nse-vl3-vpp || exit

# Deploy test apps:
try_run_line k1 create ns msm-perf-test-msm
try_run_line k1 apply -n msm-perf-test-msm -f "$parent_path/apps/nginx.yaml" || exit
try_run_line k1 -n msm-perf-test-msm scale --replicas="$replica_count" deployment/nginx

try_run_line k2 create ns msm-perf-test-msm
try_run_line k2 -n msm-perf-test-msm apply -f "$parent_path/apps/fortio.yaml" || exit
try_run_line k2 -n msm-perf-test-msm scale --replicas="$replica_count" deployment/fortio

try_run_line k1 -n msm-perf-test-msm wait --for=condition=ready --timeout=1m pod -l app=nginx || exit
# k1 -n nsm-system exec daemonsets/forwarder-vpp -it -- bash -c 'vppctl clear trace && vppctl trace add virtio-input 10000 && vppctl trace add af-packet-input 10000 && vppctl trace add memif-input 10000'
# k2 -n nsm-system exec daemonsets/forwarder-vpp -it -- bash -c 'vppctl clear trace && vppctl trace add virtio-input 10000 && vppctl trace add af-packet-input 10000'
try_run_line k2 -n msm-perf-test-msm wait --for=condition=ready --timeout=1m pod -l app=fortio || exit

# sleep 15
# k1 -n nsm-system exec daemonsets/forwarder-vpp -it -- vppctl show trace max 10000 > trace1.log
# k2 -n nsm-system exec daemonsets/forwarder-vpp -it -- vppctl show trace max 10000 > trace2.log
# k1 -n nsm-system exec daemonsets/forwarder-vpp -it -- vppctl clear trace
# k2 -n nsm-system exec daemonsets/forwarder-vpp -it -- vppctl clear trace
# try_run_line k2 -n msm-perf-test-msm scale --replicas="10" deployment/fortio
# try_run_line k2 -n msm-perf-test-msm wait --for=condition=ready --timeout=1m pod -l app=fortio || exit

# k2 -n msm-perf-test-msm exec deployments/fortio -it -c cmd-nsc -- apk add tcpdump
# echo doing tcpdump
# k2 -n msm-perf-test-msm exec deployments/fortio -it -c cmd-nsc -- tcpdump -i nsm-1 -f '!icmp' -U -w - > ./kuma-sidecar.pcap &
# sleep 30
# pkill -f "msm-perf-test-msm exec deployments/fortio -it -c cmd-nsc -- tcpdump"

"$parent_path"/port-forward-fortio.sh 8080 "$port_file"
