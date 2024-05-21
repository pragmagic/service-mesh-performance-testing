
# Kind cluster setup for local testing

Create clusters:

```bash
./cluster-setup/kind-local/kind-create-1.sh
./cluster-setup/kind-local/kind-create-2.sh
```

Setup test environment:

```bash
source ./cluster-setup/kind-local/env-kind-kind.sh
```

Taint nodes:

```bash
k1 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/master:NoSchedule
k2 taint node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/master:NoSchedule
```

# Execute tests

```bash
./scripts/test_suite.sh
```

# Cleanup

```bash
kind delete cluster --name kind-1
kind delete cluster --name kind-2
```
