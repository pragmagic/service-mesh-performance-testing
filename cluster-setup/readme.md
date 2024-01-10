
# Cluster setup

This folder contains scripts to set up clusters for testing.

# AWS authentication

Create file `cluster-setup/private/aws-login.sh` with the following content:

```bash
#!/usr/bin/env false

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
```

Put your values into variables.

No additional actions are needed.

# Packet authentication

Create file `./cluster-setup/private/packet-login.sh` with the following content:

```bash
#!/usr/bin/env false

export PROJECT_ID=
# METAL_AUTH_TOKEN and PACKET_API_KEY should have the same value
# METAL_AUTH_TOKEN is for metal cli
# PACKET_API_KEY is for clusterctl
export METAL_AUTH_TOKEN=
export PACKET_API_KEY=
export METRO=
# your public key
export SSH_KEY=
```

When using a pre-configured packet cluster, place kubeconfig files here:
- `./cluster-setup/private/kubeconfig/packet_1.yaml`
- `./cluster-setup/private/kubeconfig/packet_2.yaml`

And then run the following commands:

```bash
. ./cluster-setup/env-packet.sh 1 1 true
. ./cluster-setup/env-packet.sh 2 2 true
```

Metallb setup:

```bash
k1 create ns metallb-system
k1 -n metallb-system create cm config
k1 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
k2 create ns metallb-system
k2 -n metallb-system create cm config
k2 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
```

# Creating/deleting clusters

After you set up required authentication you can just use `-create` and `-delete` scripts.

# Environment

Run `env-<cluster1>-<cluster2>` for initial setup, to create kubeconfig files.

Run `env-restore.sh` to restore last used environment in a new terminal session.

For example:

```bash
# packet+packet
. ./cluster-setup/env-packet.sh 1 1 true                                                                             
. ./cluster-setup/env-packet.sh 2 2 true

k1 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/master:NoSchedule
k2 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/master:NoSchedule

k1 create ns metallb-system
k1 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
k1 -n metallb-system create cm config
k2 create ns metallb-system
k2 apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
k2 -n metallb-system create cm config

# packet+packet: in other terminals
. ./cluster-setup/env-restore.sh split

# aws+aws
. ./cluster-setup/env-aws-aws.sh

# aws+aws: in other terminals
. ./cluster-setup/env-restore.sh
```

# Node count and taints

These tests are meant to be run in clusters with only one worker node,
to ensure consistent performance for all service meshes.

Some clusters, like AWS, don't have distinct control plane nodes.
Other clusters may have them.

Before running tests make sure that your control plane nodes are tainted
to avoid splitting pods between nodes.

```bash
k1 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/control-plane:NoSchedule
k2 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/control-plane:NoSchedule
```
