#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

source "$parent_path"/private/aws-login.sh || exit

kube_config_dir=/tmp/kind-configs
mkdir -p "$kube_config_dir" || exit

aws_kubeconfig="$kube_config_dir"/kubeconfig-aws-1
KUBECONFIG="$aws_kubeconfig" eksctl create cluster -f "$parent_path"/aws-1.yaml || exit

"$parent_path"/aws--setup-security-1.sh || exit
