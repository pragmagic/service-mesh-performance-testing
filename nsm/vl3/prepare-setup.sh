#!/usr/bin/env bash

parent_path=$( cd "$(dirname "$0")" ; pwd -P ) || exit

("$parent_path/gen/interdomain/suite.gen.sh" setup) || exit
("$parent_path/gen/interdomain/nsm/suite.gen.sh" cleanup) || exit

