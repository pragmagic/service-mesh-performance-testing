
# service-mesh-performance-testing

This repo contains test scripts used to setup
various service meshes in multi-cluster scenarios
and run performance tests.

# Prerequisites

You need to have 2 clusters with working LoadBalancer.
Each node must be reachable by other nodes by node IP.

If you don't have clusters yet, you can use scripts in `cluster-setup` folder as examples.

You need to have 2 kubeconfig files, place them
in `KUBECONFIG1` and `KUBECONFIG2` environment variables.

# Run tests

```bash
./scripts/test_suite.sh
```

# Generating result table from raw JSON files

```bash
./scripts/extract_statistics.sh ./scripts/results/suites/2023-11-14-T17-12-aws_aws/ ./test-out
```
