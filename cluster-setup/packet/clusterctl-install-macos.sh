#!/usr/bin/env bash

function install_clusterctl() {
    clusterctl version && return

    curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.6.2/clusterctl-darwin-amd64 -o clusterctl || exit
    chmod +x ./clusterctl || exit
    sudo mv ./clusterctl /usr/local/bin/clusterctl || exit
    clusterctl version || exit
}

function install_metal() {
    metal --version && return

    go install github.com/equinix/metal-cli/cmd/metal@latest
    metal --version || exit
}

(install_clusterctl && install_metal)
