#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

("$parent_path/gen/interdomain/suite.gen.sh" cleanup) || exit
