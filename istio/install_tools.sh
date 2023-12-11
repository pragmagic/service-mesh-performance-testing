#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

install_path=$parent_path/tmp
istio_version=${ISTIO_VERSION:-1.19.3}

function install_istio() {
    istioctl version --kubeconfig /dev/null | grep "$istio_version" && { 
        echo "required version is already installed (globally)"
        return
    }
    "$install_path/istio-$istio_version/bin/istioctl" version --kubeconfig /dev/null | grep "$istio_version" && { 
        echo "required version is already installed (locally)"
    } || (
        echo "installing istioctl $istio_version"
        mkdir -p "$install_path"
        cd "$install_path"
        curl -L https://istio.io/downloadIstio | ISTIO_VERSION="$istio_version" TARGET_ARCH=x86_64 sh -
    ) || return
    export PATH="$install_path/istio-$istio_version/bin:$PATH"
    istioctl version --kubeconfig /dev/null | grep "$istio_version"
}

install_istio || return || exit
