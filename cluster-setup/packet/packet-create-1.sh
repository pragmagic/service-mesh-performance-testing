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

. "$parent_path"/private/packet-login.sh

export CONTROLPLANE_NODE_TYPE=c3.medium.x86
export WORKER_NODE_TYPE=c3.medium.x86

metal capacity check -m "$METRO" -P c3.medium.x86 -q 2 | grep da | grep true || exit

export CLUSTER_NAME=msm-perf-test-1
clusterctl generate cluster msm-perf-test-1 \
  --kubernetes-version v1.28.3 \
  --control-plane-machine-count=1 \
  --worker-machine-count=1 \
  | sed 's/"eipTag"/"metro": "'"$METRO"'", "loadbalancer": "metallb:\/\/\/", "eipTag"/' \
  > "$parent_path"/private/packet-cluster-1.yaml || exit

kubectl apply -f "$parent_path"/private/packet-cluster-1.yaml
