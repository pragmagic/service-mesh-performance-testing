#!/bin/bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

if [ -z "$1" ]; then echo 1st arg 'source_folder' is missing; exit 1; fi

source_folder=$1

result_folder="$parent_path"/gen

function generate_suites() {
    echo "generating interdomain..."
    gotestmd "$source_folder"/examples "$result_folder" --bash --match interdomain --retry || exit
    gotestmd "$source_folder"/examples "$result_folder" --bash --match nsm --retry || exit
}

rm -rf "$result_folder"

(generate_suites) || exit
