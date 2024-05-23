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

kubectl get providers > /dev/null 2>&1 || { echo "management cluster is not initialized"; exit 1; }

echo cluster:
kubectl get cluster
echo packetcluster:
kubectl get packetcluster
echo kubeadmcontrolplane:
kubectl get kubeadmcontrolplane
echo machinedeployment:
kubectl get machinedeployment
echo packetmachine:
kubectl get packetmachine
