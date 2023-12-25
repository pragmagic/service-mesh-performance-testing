#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

source ./scripts/try_run.sh || exit

echo running "$0"

("$parent_path"/gen/interdomain/loadbalancer/suite.gen.sh cleanup)

true
