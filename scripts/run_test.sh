#!/usr/bin/env bash

function k1() { kubectl --kubeconfig "$KUBECONFIG1" "$@" ; }
function k2() { kubectl --kubeconfig "$KUBECONFIG2" "$@" ; }

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

if [ -z "$1" ]; then echo "1st arg 'name' is missing"; exit 1; fi
if [ -z "$2" ]; then echo "2nd arg 'result_folder' is missing"; exit 1; fi
if [ -z "$3" ]; then echo "3rd arg 'test_iterations' is missing"; exit 1; fi
if [ -z "$4" ]; then echo "4th arg 'test_url' is missing"; exit 1; fi
if [ -z "$5" ]; then echo "5th arg 'deploy_script' is missing"; exit 1; fi
if [ -z "$6" ]; then echo "6th arg 'clear_script' is missing"; exit 1; fi
if [ -z "$7" ]; then echo "7th arg 'qps_list' is missing"; exit 1; fi

test_name=test-$(TZ=UTC date +%F-T%H-%M)-$1
result_folder=$2
if [ ! "$USE_EXACT_RESULT_FOLDER" = "1" ]; then
    result_folder=$2/$test_name
fi
test_iterations=$3
test_url=$4
deploy_script=$5
clear_script=$6
qps_list=$7
replicas=${8:-1}
retries=${9:-1}
duration=${10:-60s}

echo "test_name: $test_name"
echo "result_folder: $result_folder"
echo "test_iterations: $test_iterations"
echo "test_url: $test_url"
echo "deploy_script: $deploy_script"
echo "clear_script: $clear_script"
echo "qps_list: $qps_list"
echo "replicas: $replicas"
echo "retries: $retries"
echo "duration: $duration"

mkdir -p "$result_folder" || exit

connections1=1

function makeConfig() {
    url=$1
    qps=$2
    resolution=$3
    connections=$4
    duration=$5
    sed \
        -e "s^<url>^$url^g" \
        -e "s/<qps>/$qps/g" \
        -e "s/<resolution>/$resolution/g" \
        -e "s/<connections>/$connections/g" \
        -e "s/<duration>/$duration/g" \
        "$parent_path/fortio-config-template.json"
}

function captureState() {
    set -x
    k1 get svc -A -o wide
    k2 get svc -A -o wide
    k1 get pod -A -o wide
    k2 get pod -A -o wide
    k1 describe node
    k2 describe node
    set +x
}

function parallel_fortio() {
    port_file=$1
    name_prefix=$2
    config=$3
    pids=
    ports=
    if [ -f "$port_file" ]; then
        ports=$(cat "$port_file")
    else
        ports=8080
    fi
    for port in $ports; do
        curl -s -d "$config" "localhost:$port/fortio/rest/run" > "$name_prefix-$port.json" &
        pids="$pids $!"
    done

    exit_code=0
    for pid in $pids; do
        wait "$pid"
        ec=$?
        [ "$ec" = 0 ] || { exit_code="$ec"; echo "curl failed: $ec"; }
    done
    (exit $exit_code)
}

function deploy_test_cleanup() (
    test_full_name=$1
    deploy_logs=$2
    warmup_results=$3
    proper_results=$4
    config=$5
    deploy_script=$6
    clear_script=$7
    replicas=$8
    retries=$9

    port_file="$parent_path/tmp/ports"
    mkdir -p "$(dirname "$port_file")"

    #  we can use trap EXIT because this function is wrapped into () instead of {}
    trap '
    pkill -f "capture_load.sh $test_full_name"
    echo saving pod layout... "$deploy_logs/$test_full_name-pod_state.log"
    captureState > "$deploy_logs/$test_full_name-pod_state.log" 2>&1
    #1 cluster-info dump --output yaml --all-namespaces --output-directory "$deploy_logs/$test_full_name-dump-1"
    #2 cluster-info dump --output yaml --all-namespaces --output-directory "$deploy_logs/$test_full_name-dump-2"
    echo running cleanup... "$deploy_logs/$test_full_name-clear.log"
    rm -f $port_file
    "$clear_script" > "$deploy_logs/$test_full_name-clear.log" 2>&1
    ' EXIT

    echo running deploy... "$deploy_logs/$test_full_name-deploy.log"
    "$deploy_script" "$replicas" "$port_file" > "$deploy_logs/$test_full_name-deploy.log" 2>&1 || { echo deploy failed; exit 1; }

    "$parent_path"/capture_load.sh "$test_full_name" k1 2>&1 > "$deploy_logs/$test_full_name-top1.log" &
    "$parent_path"/capture_load.sh "$test_full_name" k2 2>&1 > "$deploy_logs/$test_full_name-top2.log" &

    echo doing warmup run...
    parallel_fortio "$port_file" "$warmup_results/$test_full_name-warmup" "$config" || { echo running failed; exit 1; }

    for ((i = 1; i <= $retries; i++)); do
        i0=$(printf "%02d" $i)
        echo doing main run $i0...
        parallel_fortio "$port_file" "$proper_results/$test_full_name-$i0" "$config" || { echo running failed; exit 1; }
    done

    echo checking main run results:
    # we are printing results to console
    # but we don't want to break execution so we don't report errors
    "$parent_path"/validate_json.sh "$proper_results/$test_full_name"* || true
)

function run_with_parameters() {
    test_name=$1
    result_folder=$2
    iterations=$3
    url=$4
    qps=$5
    connections=$6
    duration=$7
    deploy_script=$8
    clear_script=$9
    replicas=${10}
    retries=${11}

    config=$(makeConfig "$url" "$qps" 0.00005 "$connections" "$duration")
    config_name="q$qps-c$connections-d$duration"

    deploy_logs=$result_folder/deploy
    warmup_results=$result_folder/warmup
    proper_results=$result_folder/proper
    mkdir -p "$deploy_logs" "$warmup_results" "$proper_results"

    echo "config name: $config_name"
    
    echo "measure for $iterations iterations"
    for i in $(seq -w 1 1 "$iterations")
    do
        echo "round $i"
        start_time="$(date -u +%s)"
        test_full_name=$test_name-$config_name-$(printf "%02d" $i)

        deploy_test_cleanup \
            "$test_full_name" \
            "$deploy_logs" \
            "$warmup_results" \
            "$proper_results" \
            "$config" \
            "$deploy_script" \
            "$clear_script" \
            "$replicas" \
            "$retries"
        result_code=$?

        elapsed=$(($(date -u +%s)-start_time))
        echo "elapsed during round $i: $elapsed"

        if [ ! "$result_code" = 0 ]; then
            echo "error $result_code"
            return $result_code
        fi
    done
}

echo running tests for "$test_url"
for current_qps in $qps_list
# for current_qps in "$qps1" "$qps2" "$qps3"
do
    echo "testing qps $current_qps"
    run_with_parameters \
        "$test_name" \
        "$result_folder" \
        "$test_iterations" \
        "$test_url" \
        "$current_qps" \
        "$connections1" \
        "$duration" \
        "$deploy_script" \
        "$clear_script" \
        "$replicas" \
        "$retries" \
        || return || exit
        # || echo skipping error
done
