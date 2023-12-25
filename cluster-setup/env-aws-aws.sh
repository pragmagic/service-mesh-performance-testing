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

kube_config_dir=/tmp/kube-configs

echo '#!/usr/bin/env false "This script should be sourced in a shell, not executed directly"
unset CLUSTER1_CIDR
unset CLUSTER2_CIDR
export KUBECONFIG1="'"$kube_config_dir"'"/kubeconfig-aws-1
export KUBECONFIG2="'"$kube_config_dir"'"/kubeconfig-aws-2
export K8S_ENV_NAME=aws_aws
source "$1"/aws-login.sh
' > "$parent_path"/private/current-env.sh
chmod +x "$parent_path"/private/current-env.sh

# ===== fetch kubeconfig =====

source "$parent_path"/env-restore.sh || return || exit
source "$parent_path"/env--kubeconfig-aws.sh "$KUBECONFIG1" aws-msm-perf-test-1 || return || exit
source "$parent_path"/env--kubeconfig-aws.sh "$KUBECONFIG2" aws-msm-perf-test-2 || return || exit
