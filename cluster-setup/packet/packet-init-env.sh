#!/usr/bin/env bash

# ===== get script folder =====
shellname=$(ps -cp "$$" -o command="")
if [ "$shellname" = "bash" ]; then
    script_path="${BASH_SOURCE[0]}"
elif [ "$shellname" = "zsh" ]; then
    script_path="${(%):-%x}"
else
    echo "unsupported shell $shellname"
    return 1
fi
parent_path=$( cd "$(dirname "$script_path")" && pwd -P ) || return 1
# ===== ===== =====

config=$1

if [ -z "$config" ]; then
    echo "You must specify a path to existing kubeconfig file for clusterctl management"
    return 1
fi

export KUBECONFIG="$config"

. "$parent_path"/private/packet-login.sh || return 1

clusterctl init --infrastructure packet:v0.8.0
