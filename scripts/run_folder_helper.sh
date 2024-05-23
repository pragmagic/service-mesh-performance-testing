#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

function test_folder() (
    echo "run $0"
    result_folder="$1"
    iterations="$2"
    qps_list="$3"
    replicas=$4
    retries=$5
    duration=$6
    folder=$7

    info_script="$folder"/info.sh
    test_name=$($info_script name) || return
    test_url=$($info_script url) || return

    deployments_path="$parent_path"/tmp/deployments-k8s
    if [ -f "$folder"/generate.sh ]; then
        "$folder"/generate.sh $(realpath "$deployments_path") || return
    fi

    #  we can use trap EXIT because this function is wrapped into () instead of {}
    trap "echo 'run prepare-cleanup...' \"$result_folder/logs/$test_name-prepare-cleanup.log\";
        \"$folder\"/prepare-cleanup.sh > \"$result_folder/logs/$test_name-prepare-cleanup.log\" 2>&1" \
        EXIT

    LOG_PREFIX="prepare-setup"
    LOG_FILE=/dev/null
    run_line_logged "$folder"/prepare-setup.sh '>' "$result_folder/logs/$test_name-prepare-setup.log" '2>&1' || exit

    # Run tests
    start_time="$(date -u +%s)"
    USE_EXACT_RESULT_FOLDER=1 "$parent_path"/../scripts/run_test.sh \
        "$test_name" \
        "$result_folder/$test_name" \
        "$iterations" \
        "$test_url" \
        "$folder"/deploy.sh \
        "$folder"/clear.sh \
        "$qps_list" \
        "$replicas" \
        "$retries" \
        "$duration" \
        || return
    elapsed=$(( "$(date -u +%s)" - start_time ))
    echo "elapsed during testing for $test_name: $elapsed"
)
