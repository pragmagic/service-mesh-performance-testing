#!/usr/bin/env bash

function install_aws() {
    # check if aws is already installed
    aws --version && return

    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg" || exit
    sudo installer -pkg AWSCLIV2.pkg -target / || exit
    rm -f AWSCLIV2.pkg || exit

    # verify aws works
    aws --version || exit
}

function install_eksctl() {
    # check if eksctl is already installed
    eksctl version && return

    ARCH=amd64
    PLATFORM=$(uname -s)_$ARCH

    curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz" || exit

    tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp || exit
    rm eksctl_$PLATFORM.tar.gz || exit

    sudo mv /tmp/eksctl /usr/local/bin || exit

    # verify eksctl works
    eksctl version || exit
}

(install_aws && install_eksctl)
