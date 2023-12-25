#!/usr/bin/env bash

arg=$1

case "$arg" in
"name")
    echo nsmvl3
    ;;
"url")
    echo "http://nginx.my-vl3-network:80"
    ;;
*)
    exit 1
    ;;
esac
