#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

source "$parent_path"/private/aws-login.sh || exit

eksctl delete cluster -f "$parent_path"/aws-1.yaml
