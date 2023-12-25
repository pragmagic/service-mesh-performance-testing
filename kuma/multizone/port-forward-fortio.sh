#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

echo running "$0"

port0=$1
port_file=$2

pods=$(k2 -n msm-perf-test-mz get pods -l app=fortio -o go-template --template="{{range .items}}{{.metadata.name}} {{end}}") || exit

[ -z "$port_file" ] || rm -f "$port_file" || exit
[ -z "$port_file" ] || touch "$port_file" || exit

port=$port0
for pod in $pods
do
    k2 -n msm-perf-test-mz port-forward pods/"$pod" "$port":8080 2>&1 | sed -e 's/^/fwd '"$pod $port"': /' &
    [ -z "$port_file" ] || echo "$port" >> "$port_file"
    port=$((port+1))
done

# it can take some time for the background job to start listening to local port
sleep 5
