#!/usr/bin/env bash

echo "
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker" | kind create cluster --config - --name kind-management
