#!/usr/bin/env bash

# ===== get script folder =====
shellname=$(ps -cp "$$" -o command="")
if [ "$shellname" = "bash" ]; then
    parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P ) || return
elif [ "$shellname" = "zsh" ]; then
    parent_path=$( cd "$(dirname "${(%):-%x}")" && pwd -P ) || return
else
    echo "unsupported shell $shellname"
    return 1
fi
# ===== ===== =====

kubeconfig="$1"
cluster_name="$2"
echo "place $cluster_name config into $kubeconfig"

rm -f "$kubeconfig" &&
KUBECONFIG="$kubeconfig" aws eks update-kubeconfig --region us-east-1 --name "$cluster_name"
