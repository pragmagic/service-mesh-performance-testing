#!/usr/bin/env bash

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

function install_metrics_server_in_cluster() {
    kctl=$1
    echo "checking $kctl"
    if $kctl top pod 2>&1 | grep "Metrics API not available"; then
        echo installing metrics API
        $kctl apply -f "$parent_path/metrics-server.yaml"
    else
        echo "$kctl already has metrict API"
    fi
}

install_metrics_server_in_cluster k1 &&
install_metrics_server_in_cluster k2
