#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

if [ -z "$1" ]; then echo "1st arg 'suite_folder' is missing"; exit 1; fi
if [ -z "$2" ]; then echo "2nd arg 'output_file' is missing"; exit 1; fi

suite_folder=$1
output_file=$2
skip_list=$3

function read_value() {
    var_name=$1
    var_name2=$2
    file=$3
    query=$4

    value="$(jq --exit-status "$query" "$file")" ||
        { echo "$query is missing from $file" 1>&2; exit 1; }
    if [ ! -z "${!var_name}" ]; then
        eval "$var_name=${!var_name},"
    fi
    eval "$var_name=${!var_name}${value}"
    if [ ! -z "${!var_name2}" ]; then
        eval "$var_name2=${!var_name2},"
    fi
    eval "$var_name2=${!var_name2}${value}"
}

function map_name() {
    name=$1
    name_map=(
        qps=QPS
        avg=Average
        avg_stddev="Average Std. Dev."
        p90=P90
        p99=P99
        p999=P99.9
        imp=Istio
        kmz=Kuma
        nsmvl3="NSM vl3"
    )
    for m in "${name_map[@]}"
    do
        key="${m%%=*}"
        value="${m#*=}"
        if [ "$key" == "$name" ]; then
            echo "$value"
            return
        fi
    done

    return 1
}

rm -f "$output_file"

# echo "test_name,qps,avg,avg_stddev,p90,p99,p99.9" >> "$output_file"
maxi=0
for folder in $suite_folder/*/proper
do
    test_name="$(basename "$(dirname "$folder")")"
    case $skip_list in
        *$test_name* )
            echo skipping $test_name
            continue
            ;;
    esac
    names="$names,$test_name"
    i=0
    for file in $folder/*-q*-c*-d*s-*-01-*.json
    do
        echo "processing $file"
        # VALIDATE_SKIP_PRINT=true "$parent_path"/validate_json.sh || exit
        read_value qps_${i} qps_${test_name} "$file" .ActualQPS || exit
        read_value avg_${i} avg_${test_name} "$file" '(.DurationHistogram.Avg) * 1000' || exit
        read_value avg_stddev_${i} avg_stddev_${test_name} "$file" '.DurationHistogram.StdDev * 1000' || exit
        read_value p90_${i} p90_${test_name} "$file" '.DurationHistogram.Percentiles[] | select(.Percentile==90) | .Value * 1000' || exit
        read_value p99_${i} p99_${test_name} "$file" '.DurationHistogram.Percentiles[] | select(.Percentile==99) | .Value * 1000' || exit
        read_value p999_${i} p999_${test_name} "$file" '.DurationHistogram.Percentiles[] | select(.Percentile==99.9) | .Value * 1000' || exit
        # echo "$test_name-$i,$qps,$avg,$avg_stddev,$p90,$p99,$p999" >> "$output_file" || exit
        if [ $i -gt $maxi ]; then maxi=$i; fi
        i=$((i+1))
    done
done


header_names=
for name in $(echo $names | tr , ' ')
do
    header_names="${header_names},$(map_name $name)"
done
echo creating output file...
for valtype in qps avg avg_stddev p90 p99 p999; do
    echo '' >> "$output_file" || exit
    echo "$(map_name ${valtype})${header_names}" >> "$output_file" || exit
    for i in $(seq 0 $maxi); do
        var_name=${valtype}_${i}
        # echo var_name == $var_name
        echo "$i,${!var_name}" >> "$output_file" || exit
    done
    echo "$(map_name ${valtype}),Average,Percent to first" >> "$output_file" || exit
    first_average=
    for name in $(echo $names | tr , ' ')
    do
        var_name=${valtype}_${name}
        average=$(jq "($(echo ${!var_name} | tr , +)) / $((maxi+1))" <<< {}) || exit
        [ ! -z "$first_average" ] || first_average=$average
        percent=$(jq "$average / $first_average * 100" <<< {}) || exit
        echo "$(map_name $name),$average,$percent" >> "$output_file" || exit
    done
done
