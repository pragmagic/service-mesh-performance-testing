
# Istio test

This folder contains tests for Istio service mesh.

# Test Istio Multi-cluster in Multi-Primary mode

Generate setup scripts:

```bash
./scripts/install_nsm_deployments.sh
./istio/multiprimary/generate.sh $(realpath ./scripts/tmp/deployments-k8s)
```

Prepare cluster for testing:

```bash
./istio/multiprimary/prepare-setup.sh > ./tmp/imp-prepare-setup.log 2>&1
```

Test if you environment is set up correctly before running long tests:

```bash
# deploy service mesh and test apps
./istio/multiprimary/deploy.sh > ./tmp/imp-setup.log 2>&1

# run a single test without setup and cleanup
./scripts/run_test.sh imp_manual ./tmp/manual-tests 1 "http://nginx-service.multicluster:80" true true 1000000 1 1 1s

# cleanup service mesh and test apps
./istio/multiprimary/clear.sh > ./tmp/imp-cleanup.log 2>&1
```

Run tests:

```bash
./scripts/run_test_suite.sh istio-multiprimary ./istio/results/raw/ 11 "http://nginx-service.multicluster:80" ./istio/multiprimary/deploy.sh ./istio/multiprimary/clear.sh
```

Cleanup cluster:

```bash
./istio/multiprimary/prepare-cleanup.sh > ./tmp/imp-prepare-cleanup.log 2>&1
```
