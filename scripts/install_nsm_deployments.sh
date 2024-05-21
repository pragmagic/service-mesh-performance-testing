#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

echo running "$0"

repo=https://github.com/networkservicemesh/deployments-k8s.git
branch=v1.11.1

echo "repo == $repo"
echo "branch == $branch"

install_path="$parent_path/tmp/deployments-k8s"
mkdir -p "$(dirname "$install_path")"
rm -rf "$install_path"

function download_deployments() (
    git clone --branch "$branch" --depth 1 "$repo" "$install_path" || exit
    (cd "$install_path" && git rev-parse HEAD)
    echo dowloaded into "$install_path"
)

download_deployments
