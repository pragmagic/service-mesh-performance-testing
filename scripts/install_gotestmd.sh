#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

echo running "$0"

# repo=https://github.com/d-uzlov/gotestmd.git
# branch=fix-bash
repo=https://github.com/networkservicemesh/gotestmd.git
branch=main

echo "repo == $repo"
echo "branch == $branch"

install_path="$parent_path/tmp/gotestmd"
mkdir -p "$(dirname "$install_path")"
rm -rf "$install_path"

# you can install a package directly:
#       go install github.com/networkservicemesh/gotestmd@main
# but golang doesn't allow you to install anything from a fork
# so we clone repo and install it locally, just in case we want to use a fork
function install_gotestmd() {
    git clone --branch "$branch" --depth 1 "$repo" "$install_path" || exit
    cd "$install_path"
    go install .
}

# we don't check version before install
# because we want to overwrite
# whatever was installed before
( install_gotestmd ) && gotestmd --version
