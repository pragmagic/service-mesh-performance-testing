#!/usr/bin/env bash

save_directory=$1

relevant_files=$(git ls-files | grep \
    -e ^kuma/vl3msm/ \
    -e ^kuma/multizone/ \
    -e ^kuma/singlecluster/ \
    -e '^kuma/[^/]*.sh' \
    -e ^scripts/) \
    || exit

zip "$save_directory"/repo-state.zip $relevant_files > /dev/null || exit
