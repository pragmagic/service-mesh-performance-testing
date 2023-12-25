
# Kuma test

This folder contains tests for Kuma service mesh.

# Test Kuma multi-zone scenario

Generate setup scripts:

```bash
./scripts/install_nsm_deployments.sh
./kuma/multizone/generate.sh $(realpath ./scripts/tmp/deployments-k8s)
```

Prepare cluster for testing:

```bash
./kuma/multizone/prepare-setup.sh > ./tmp/kmz-prepare-setup.log 2>&1
```

Test if you environment is set up correctly before running long tests:

```bash
# deploy Kuma multi-zone and test apps
./kuma/multizone/deploy.sh > ./tmp/kmz-setup.log 2>&1

# run a single test without setup and cleanup
./scripts/run_test.sh kmz_manual ./tmp/manual-tests 1 "http://nginx-service_msm-perf-test-mz_svc_80.mesh:80" true true 1000000 1 1 1s

# cleanup Kuma multi-zone and test apps
./kuma/multizone/clear.sh > ./tmp/kmz-cleanup.log 2>&1
```

Run tests:

```bash
./scripts/run_test.sh kmz_aws_aks ./kuma/results/raw/ 5 "http://nginx-service_msm-perf-test-mz_svc_80.mesh:80" ./kuma/multizone/deploy.sh ./kuma/multizone/clear.sh 1000000
```

Cleanup cluster:

```bash
./kuma/multizone/prepare-cleanup.sh > ./tmp/kmz-prepare-cleanup.log 2>&1
```
