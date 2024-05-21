#!/usr/bin/env bash

# ===== get script folder =====
shellname=$(ps -cp "$$" -o command="")
if [ "$shellname" = "bash" ]; then
    script_path="${BASH_SOURCE[0]}"
elif [ "$shellname" = "zsh" ]; then
    script_path="${(%):-%x}"
else
    echo "unsupported shell $shellname"
    return 1 || exit 1
fi
parent_path=$( cd "$(dirname "$script_path")" && pwd -P ) || return || exit
# ===== ===== =====

kind get kubeconfig --name kind-1 > "$parent_path"/kubeconfig/config1
kind get kubeconfig --name kind-2 > "$parent_path"/kubeconfig/config2
export KUBECONFIG1="$parent_path"/kubeconfig/config1
export KUBECONFIG2="$parent_path"/kubeconfig/config2
export CLUSTER1_CIDR=172.21.0.0/24
export CLUSTER2_CIDR=172.21.1.0/24
export K8S_ENV_NAME=kind_kind
export USE_KIND_NODE=true
