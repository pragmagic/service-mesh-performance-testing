#!/usr/bin/env bash

if [ -z "$1" ]; then echo "1st arg 'kubeconfig' is missing"; exit 1; fi
if [ -z "$2" ]; then echo "2nd arg 'result_folder' is missing"; exit 1; fi
if [ -z "$3" ]; then echo "3rd arg 'kube_proxy_label' is missing"; exit 1; fi

# Kube-proxy labels in different clusters:
# kind: k8s-app=kube-proxy
# gke:  component=kube-proxy
# aws:  k8s-app=kube-proxy

kubeconfig=$1
result_folder=$2
kube_proxy_label=$3

function k1() { kubectl --kubeconfig "$kubeconfig" "$@" ; }

mkdir -p "$result_folder"

k1 get nodes -o wide > "$result_folder/nodes.log"

k1 -n kube-system describe pod -l "$kube_proxy_label" >  "$result_folder/pod-description-$node.log"

pods=$(k1 -n kube-system get pod -l "$kube_proxy_label" -o name)
for pod in $pods
do
    node=$(k1 -n kube-system get "$pod" -o go-template --template="{{.spec.nodeName}}")
    k1 -n kube-system exec "$pod" -- cat /proc/cpuinfo > "$result_folder/cpuinfo-$node.log" || exit
done

