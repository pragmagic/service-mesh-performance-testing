#!/usr/bin/env bash

arg=$1

case "$arg" in
"name")
    echo imp
    ;;
"url")
    echo "http://nginx-service.multicluster:80"
    ;;
*)
    exit 1
    ;;
esac
