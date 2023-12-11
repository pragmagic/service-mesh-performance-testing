#!/usr/bin/env bash

function create_archive() (
    directory="$1"
    cd "$directory" || exit
    if [ -f details.zip ]; then
        echo details.zip already exists in "$directory"
        exit 0
    fi

    echo moving folders to achive: \
        */deploy \
        */warmup

    echo "creating archive"
    zip -r details.zip \
        */deploy \
        */warmup \
        > /dev/null \
        || exit

    echo "removing archived folders"
    rm -rf \
        */deploy \
        */warmup \
        || exit
    
    echo created details.zip in "$directory"
)

for dir in "$@"
do
    create_archive $dir || exit
done
