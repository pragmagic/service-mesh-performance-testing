#!/usr/bin/env false "This script should be sourced in a shell, not executed directly"

function try_run() {
    command="$1"
    attempt=0
    retry_interval=1
    timeout="${RETRY_TIMEOUT_SECONDS:-300}"
    start_time="$(date -u +%s)"
    echo "===== next command ====="
    echo "$command"
    while true; do
        attempt=$((attempt + 1))
        echo "===== attempt $attempt ====="
        echo "current time $(date +"%Y-%m-%dT%H:%M:%S%z")"
        source /dev/stdin <<<"$(echo "${command}")"
        retval=$?
		echo
        echo "retval = $retval"
        current_time="$(date -u +%s)"
        elapsed=$((current_time-start_time))
        echo "elapsed = $elapsed"
        [ $retval = 0 ] && echo "===== command success =====" && return 0
        [ "$elapsed" -gt "$timeout" ] && echo "===== command timed out =====" && return 1
        sleep $retry_interval
    done
}

function try_run_line() {
    command="$*"
    attempt=0
    retry_interval=1
    timeout="${RETRY_TIMEOUT_SECONDS:-300}"
    start_time="$(date -u +%s)"
    echo "===== next command ====="
    echo "$command"
    while true; do
        attempt=$((attempt + 1))
        echo "===== attempt $attempt ====="
        echo "current time $(date +"%Y-%m-%dT%H:%M:%S%z")"
        source /dev/stdin <<<"$(echo "${command}")"
        retval=$?
		echo
        echo "retval = $retval"
        current_time="$(date -u +%s)"
        elapsed=$((current_time-start_time))
        echo "elapsed = $elapsed"
        [ $retval = 0 ] && echo "===== command success =====" && return 0
        [ "$elapsed" -gt "$timeout" ] && echo "===== command timed out =====" && return 1
        sleep $retry_interval
    done
}

function try_run_line_once() {
    command="$*"
    start_time="$(date -u +%s)"
    echo "===== next command ====="
    echo "$command"
    echo "current time $(date +"%Y-%m-%dT%H:%M:%S%z")"
    source /dev/stdin <<<"$(echo "${command}")"
    retval=$?
    echo
    echo "retval = $retval"
    current_time="$(date -u +%s)"
    elapsed=$((current_time-start_time))
    echo "elapsed = $elapsed"
    if [ $retval = 0 ]; then
        echo "===== command finished: success ====="
    else
        echo "===== command finished: fail ====="
    fi
    return "$retval"
}

function run_line_logged() {
    log_prefix=$LOG_PREFIX || exit
    log_file=$LOG_FILE || exit
    need_terminal=${LOG_IN_TERMINAL:-true}
    if [ "$need_terminal" = 'true' ]; then
        redirect_null=''
    else
        redirect_null='> /dev/null'
    fi
    # We need to do > >(...) instead of posix pipes 
    # because pipes create a new shell,
    # which prevents usage of exported bash variables and environment variables.
    {
        try_run_line_once "$*"
    } > >(
        # AWK is for prefix only, fflush is required
        # because pipes that aren't connected to a terminal are fully buffered.
        awk -v prefix="$log_prefix: " '{print prefix $0; fflush()}' | 
        eval tee -a "'$log_file'" $redirect_null
    ) 2>&1
}
