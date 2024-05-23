#!/usr/bin/env false "This script should be sourced in a shell, not executed directly"

# ===== get script folder =====
shellname=$(ps -cp "$$" -o command="")
if [ "$shellname" = "bash" ]; then
    script_path="${BASH_SOURCE[0]}"
elif [ "$shellname" = "zsh" ]; then
    script_path="${(%):-%x}"
else
    echo "unsupported shell $shellname"
    return 1 || exit 1
fi
parent_path=$( cd "$(dirname "$script_path")" && pwd -P ) || return || exit
# ===== ===== =====

split_configs=${1:-}

[ "$split_configs" = 'split' ] || source "$parent_path"/private/current-env.sh "$parent_path"/private
[ ! "$split_configs" = 'split' ] || source "$parent_path"/private/current-env-1.sh "$parent_path"/private
[ ! "$split_configs" = 'split' ] || source "$parent_path"/private/current-env-2.sh "$parent_path"/private
source "$parent_path"/env--autocomplete.sh
