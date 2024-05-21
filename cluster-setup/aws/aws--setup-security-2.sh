#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

source "$parent_path"/private/aws-login.sh || exit

AWS_CLUSTER_NAME=aws-msm-perf-test-2

sg=$(aws ec2 describe-security-groups --filter Name=tag:aws:eks:cluster-name,Values="${AWS_CLUSTER_NAME}" --region="us-east-1" --query 'SecurityGroups[0].GroupId' --output text)

echo "security group is $sg"

## Setup security group rules
for i in {1..25}
do
    if [[ -n $sg  ]]; then
        break
    fi
    sleep 30
    echo attempt "$i" has failed
    sg=$(aws ec2 describe-security-groups --filter Name=tag:aws:eks:cluster-name,Values="${AWS_CLUSTER_NAME}" --region="us-east-1" --query 'SecurityGroups[0].GroupId' --output text)
done

if [[ -z $sg  ]]; then
    echo "Security group is not found"
    exit 1
fi

### authorize wireguard
aws ec2 authorize-security-group-ingress --region="us-east-1" --group-id "$sg" --protocol tcp --port 51820 --cidr 0.0.0.0/0 | cat
aws ec2 authorize-security-group-ingress --region="us-east-1" --group-id "$sg" --protocol udp --port 51820 --cidr 0.0.0.0/0 | cat
### authorize vxlan
aws ec2 authorize-security-group-ingress --region="us-east-1" --group-id "$sg" --protocol tcp --port 4789 --cidr 0.0.0.0/0 | cat
aws ec2 authorize-security-group-ingress --region="us-east-1" --group-id "$sg" --protocol udp --port 4789 --cidr 0.0.0.0/0 | cat
### authorize nsmgr-proxy
aws ec2 authorize-security-group-ingress --region="us-east-1" --group-id "$sg" --protocol tcp --port 5004 --cidr 0.0.0.0/0 | cat
### authorize registry
aws ec2 authorize-security-group-ingress --region="us-east-1" --group-id "$sg" --protocol tcp --port 5002 --cidr 0.0.0.0/0 | cat
### authorize vl3-ipam
aws ec2 authorize-security-group-ingress --region="us-east-1" --group-id "$sg" --protocol tcp --port 5006 --cidr 0.0.0.0/0 | cat

