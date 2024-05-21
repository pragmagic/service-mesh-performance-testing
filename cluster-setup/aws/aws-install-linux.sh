#!/usr/bin/env bash

function install_aws() {
    # check if aws is already installed
    aws --version && return

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" || exit
    unzip awscliv2.zip || exit
    sudo ./aws/install || exit
    rm -rf ./aws || exit
    rm -f awscliv2.zip || exit

    # verify aws works
    aws --version || exit
}

function install_eksctl() {
    # check if eksctl is already installed
    eksctl version && return

    ARCH=amd64
    PLATFORM=$(uname -s)_$ARCH

    curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz" || exit

    # (Optional) Verify checksum
    curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_checksums.txt" \
        | grep $PLATFORM \
        | sha256sum --check \
        || exit

    tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp || exit
    rm eksctl_$PLATFORM.tar.gz || exit

    sudo mv /tmp/eksctl /usr/local/bin || exit

    # verify eksctl works
    eksctl version || exit
}

(install_aws && install_eksctl)
