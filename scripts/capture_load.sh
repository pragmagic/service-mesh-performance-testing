#!/usr/bin/env bash

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

[ -n "$2" ] || { echo "cluster arg is missing"; exit 1; }

cluster=$2
set +x
while true; do
    echo "$(TZ=UTC date +%F-T%H-%M)"
    $cluster top pod -A
    sleep 5
done
