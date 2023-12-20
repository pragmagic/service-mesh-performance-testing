#!/usr/bin/env false "This script should be sourced in a shell, not executed directly"

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

install_path="$parent_path/tmp"
kuma_version=${KUMA_VERSION:-2.4.3}

echo "kuma_version == $kuma_version"

mkdir -p "$install_path"

function install_kuma() {
    "$install_path/kuma-$kuma_version/bin/kumactl" version |
        grep "$kuma_version" && {
        echo "kumactl $kuma_version is already downloaded"
    } ||
    (
        echo "downloading kumactl $kuma_version..."
        cd "$install_path"
        curl -L https://kuma.io/installer.sh |
            VERSION="$kuma_version" ARCH=amd64 bash -
    ) || return
    export PATH="$install_path/kuma-$kuma_version/bin:$PATH"
    kumactl version | grep "$kuma_version"
}

install_kuma
