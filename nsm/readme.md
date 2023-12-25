
# NSM test

This folder contains tests for Network Service Mesh.

# Test vl3

Generate setup scripts:

```bash
./scripts/install_nsm_deployments.sh
./nsm/vl3/generate.sh $(realpath ./scripts/tmp/deployments-k8s)
```

Prepare cluster for NSM:

```bash
./nsm/vl3/prepare-setup.sh > ./tmp/vl3-prepare-setup.log 2>&1
```

Test if you environment is set up correctly before running long tests:

```bash
# deploy NSM and test apps
./nsm/vl3/deploy.sh > ./tmp/vl3-setup.log 2>&1
# or deploy NSM and apps separately
./nsm/vl3/gen/interdomain/nsm/suite.gen.sh setup > ./tmp/nsm-setup.log 2>&1
SKIP_NSM_DEPLOY=1 ./nsm/vl3/deploy.sh > ./tmp/vl3-apps-setup.log 2>&1

# run a single test without setup and cleanup
./scripts/run_test.sh nsm_manual ./tmp/manual-tests 1 "http://nginx.my-vl3-network:80" true true 1000000 1 1 1s

# cleanup NSM and test apps
./nsm/vl3/clear.sh > ./tmp/vl3-cleanup.log 2>&1
# or cleanup apps and NSM separately
SKIP_NSM_DEPLOY=1 ./nsm/vl3/clear.sh > ./tmp/vl3-apps-cleanup.log 2>&1
./nsm/vl3/gen/interdomain/nsm/suite.gen.sh cleanup > ./tmp/nsm-cleanup.log 2>&1
```

Test with vl3 DNS:
```bash
./scripts/run_test.sh vl3_aws_aks_nsm ./nsm/results/raw/ 5 "http://nginx.my-vl3-network:80" ./nsm/vl3/deploy.sh ./nsm/vl3/clear.sh 1000000
```

Cleanup cluster:

```bash
./nsm/vl3/prepare-cleanup.sh > ./tmp/vl3-prepare-cleanup.log 2>&1
```

# Validate results

```bash
./scripts/validate_json.sh ./nsm/results/suites/*/*/proper/*
```

```bash
k2 -n msm-perf-test-msm exec deployments/fortio -it -c cmd-nsc -- apk add tcpdump
k2 -n msm-perf-test-msm exec deployments/fortio -it -c cmd-nsc -- tcpdump -i nsm-1 -f '!icmp' -U -w > ./nsm-sidecar.pcap
```
