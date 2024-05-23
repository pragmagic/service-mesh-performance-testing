#!/usr/bin/env bash

function install_clusterctl() {
    clusterctl version && return

    curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.6.2/clusterctl-linux-amd64 -o clusterctl || exit
    sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
    clusterctl version || exit
}

function install_metal() {
    metal --version && return

    go install github.com/equinix/metal-cli/cmd/metal@latest
    metal --version || exit
}

(install_clusterctl && install_metal)
