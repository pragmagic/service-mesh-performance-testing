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

kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl --kubeconfig=$KUBECONFIG1 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
kubectl --kubeconfig=$KUBECONFIG1 apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
EOF
