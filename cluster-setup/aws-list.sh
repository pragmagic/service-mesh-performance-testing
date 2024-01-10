#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

source "$parent_path"/private/aws-login.sh || exit

aws eks list-clusters --region us-east-1
