#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

source ./scripts/try_run.sh || exit

echo running "$0"

("$parent_path"/gen/interdomain/loadbalancer/suite.gen.sh setup)

try_run_line k1 create ns kuma-global-cp || exit
try_run_line k1 apply -f "$parent_path"/prepare/global-cp-svc.yaml || exit

try_run_line k1 get services -n kuma-global-cp kuma-global-zone-sync -o go-template=\''{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'\' || exit

try_run 'kuma_global_cp_ip=$(k1 get services -n kuma-global-cp kuma-global-zone-sync -o go-template='"'"'{{index (index (index (index .status "loadBalancer") "ingress") 0) "ip"}}'"'"')
if [[ $kuma_global_cp_ip == *"no value"* ]]; then
    kuma_global_cp_ip=$(k1 get services -n kuma-global-cp kuma-global-zone-sync -o go-template='"'"'{{index (index (index (index .status "loadBalancer") "ingress") 0) "hostname"}}'"'"')
    kuma_global_cp_ip=$(dig +short "$kuma_global_cp_ip" | head -1) || exit
fi
# if IPv6
if [[ $kuma_global_cp_ip =~ ":" ]]; then "kuma_global_cp_ip=[$kuma_global_cp_ip]"; fi

echo kuma_global_cp_ip is "$kuma_global_cp_ip"
[[ ! -z $kuma_global_cp_ip ]]' || exit
