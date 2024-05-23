
# AWS cluster setup

This folder contains scripts to set up AWS clusters for testing.

# Authentication

Create file `cluster-setup/aws/private/aws-login.sh` with the following content:

```bash
#!/usr/bin/env false

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

Put your values into variables.

No additional actions are needed.

# Install CLI

Run `aws-install-` script to install CLI

# Prepare clusters

After you set up required authentication you can just use `aws-create` scripts:

```bash
./cluster-setup/aws/aws-create-1.sh
./cluster-setup/aws/aws-create-2.sh
```

List clusters:

```bash
./cluster-setup/aws/aws-list.sh
```

Setup test environment

Run `env-aws-aws.sh` for initial setup, to create kubeconfig files.

Taint nodes:

```bash
k1 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/master:NoSchedule
k2 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/master:NoSchedule
```

Metallb setup:

```bash
k1 create ns metallb-system
k1 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
k1 -n metallb-system create cm config
k2 create ns metallb-system
k2 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
k2 -n metallb-system create cm config
```

# Execute tests

```bash
./scripts/test_suite.sh
```

# Cleanup

```bash
./cluster-setup/aws/aws-delete-1.sh
./cluster-setup/aws/aws-delete-2.sh
```
