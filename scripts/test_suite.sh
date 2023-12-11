#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

if [ -z "$K8S_ENV_NAME" ]; then
    [ ! -z "$K8S_ENV_NAME1" ] || { echo "K8S_ENV_NAME1 is not set"; exit 1; }
    [ ! -z "$K8S_ENV_NAME2" ] || { echo "K8S_ENV_NAME2 is not set"; exit 1; }
    K8S_ENV_NAME=${K8S_ENV_NAME1}_${K8S_ENV_NAME2}
fi

. "./scripts/try_run.sh" || exit
. "./scripts/run_folder_helper.sh" || exit

iterations=5
retries=3
qps_list="6000"
# qps_list="100 1000 1000000"
replicas=1
duration=60s

default_test_list='istio/multiprimary kuma/multizone nsm/vl3'
test_list=${1:-$default_test_list}
echo will run the following folders: "$test_list"

test_stable_name="$(TZ=UTC date +%F-T%H-%M)-$K8S_ENV_NAME"
result_folder="$parent_path/results/suites/$test_stable_name"

global_start_time="$(date -u +%s)"

mkdir -p "$result_folder/logs"

# "$parent_path"/save-repo-state.sh "$result_folder"

ISTIO_VERSION=1.19.3
KUMA_VERSION=2.4.3

LOG_PREFIX="global-install"
LOG_FILE="$result_folder/logs/install.log"
# run_line_logged . ./scripts/install_gotestmd.sh || exit
run_line_logged . ./scripts/install_nsm_deployments.sh || exit
run_line_logged . ./scripts/deploy_metrics_server.sh || exit

for test_path in $test_list
do
    LOG_PREFIX="$test_path"
    LOG_FILE="$result_folder/logs/${test_path//\//-}.log"
    folder="$parent_path"/../"$test_path"
    if [ -f "$folder"/install_tools.sh ]; then
        run_line_logged . "$folder"/install_tools.sh || exit
    fi
    run_line_logged test_folder \
        "$result_folder" "$iterations" "$qps_list" "$replicas" "$retries" "$duration" \
        "$folder" \
        || exit
done

elapsed=$(( $(date -u +%s) - global_start_time ))
echo "elapsed during global (full): $elapsed"

echo validating result files...
"$parent_path"/validate_json.sh "$result_folder"/*/proper/*.json || exit

./scripts/compress-logs.sh "$result_folder"
