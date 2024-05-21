
# Equinix Metal cluster setup

This folder contains scripts to set up Equinix metal clusters for testing.

# Authentication

Create file `./cluster-setup/packet/private/packet-login.sh` with the following content:

```bash
#!/usr/bin/env false

export PROJECT_ID=
# METAL_AUTH_TOKEN and PACKET_API_KEY should have the same value
# METAL_AUTH_TOKEN is for metal cli
# PACKET_API_KEY is for clusterctl
export METAL_AUTH_TOKEN=
export PACKET_API_KEY=
# usually METRO=da
export METRO=
# your public key (get it using 'cat ~/.ssh/id_rsa.pub' or generate another one), like SSH_KEY="ssh-rsa AAAAC3NzaC1lZDI1NTE5AAAAIjAqaYj9nmCkgr4PdK username@computer"
export SSH_KEY=
```

# Install CLI

Run `clusterctl-install-` script to install CLI

# Prepare clusters

Initialize a Kind cluster for management

```bash
./cluster-setup/packet/kind-create.sh
kind get kubeconfig --name kind-management > /tmp/kubeconfigs/config-management
source ./cluster-setup/packet/packet-init-env.sh /tmp/kubeconfigs/config-management
```

Generate workload clusters

```bash
source ./cluster-setup/packet/packet-create-1.sh
source ./cluster-setup/packet/packet-create-2.sh
```

List clusters

```bash
./cluster-setup/packet/packet-list.sh
clusterctl describe --show-conditions all cluster msm-perf-test-1
clusterctl describe --show-conditions all cluster msm-perf-test-2
```

Setup test environment

```bash
source ./cluster-setup/packet/env-packet.sh 1 1
source ./cluster-setup/packet/env-packet.sh 2 2
```

When using a pre-configured packet cluster, place kubeconfig files here:

- `./cluster-setup/packet/private/kubeconfig/packet_1.yaml`
- `./cluster-setup/packet/private/kubeconfig/packet_2.yaml`

Taint nodes:

```bash
k1 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/master:NoSchedule
k2 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/master:NoSchedule
```

Install CNI

```bash
k1 apply -k https://github.com/networkservicemesh/integration-k8s-packet/scripts/defaultCNI
k2 apply -k https://github.com/networkservicemesh/integration-k8s-packet/scripts/defaultCNI
```

SPIRE server requires StorageClass
```bash
k1 apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
k1 patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

k2 apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
k2 patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

Metallb setup:

```bash
./cluster-setup/packet/packet-lb-1.sh
./cluster-setup/packet/packet-lb-2.sh
```

# Execute tests

```bash
./scripts/test_suite.sh
```

# Cleanup

```bash
./cluster-setup/packet/packet-delete-1.sh
./cluster-setup/packet/packet-delete-2.sh
kind delete cluster --name kind-management
```
