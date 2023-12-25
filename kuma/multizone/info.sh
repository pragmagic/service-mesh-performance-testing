#!/usr/bin/env bash

arg=$1

case "$arg" in
"name")
    echo kmz
    ;;
"url")
    echo "http://nginx-service_msm-perf-test-mz_svc_80.mesh:80"
    ;;
*)
    exit 1
    ;;
esac
