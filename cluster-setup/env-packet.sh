#!/usr/bin/env false "This script should be sourced in a shell, not executed directly"

# ===== get script folder =====
shellname=$(ps -cp "$$" -o command="")
if [ "$shellname" = "bash" ]; then
    script_path="${BASH_SOURCE[0]}"
elif [ "$shellname" = "zsh" ]; then
    script_path="${(%):-%x}"
else
    echo "unsupported shell $shellname"
    return 1
fi
parent_path=$( cd "$(dirname "$script_path")" && pwd -P ) || return
# ===== ===== =====


local_cluster_index=$1
remote_cluster_index=$2
skip_fetch=${3:-}
[ "$local_cluster_index" = '1' ] || [ "$local_cluster_index" = '2' ] || { echo "invalid local_cluster_index == '$local_cluster_index'"; return 1; }
[ "$remote_cluster_index" = '1' ] || [ "$remote_cluster_index" = '2' ] || { echo "invalid remote_cluster_index == '$remote_cluster_index'"; return 1; }
[ "$skip_fetch" = 'true' ] || [ "$skip_fetch" = '' ] || { echo "invalid skip_fetch == '$skip_fetch'"; return 1; }

[ "$skip_fetch" = 'true' ] || kubectl get providers > /dev/null 2>&1 || { echo "management cluster is not initialized"; return 1; }

kube_config_path=$parent_path/private/kubeconfig/packet_$remote_cluster_index.yaml

echo '#!/usr/bin/env false "This script should be sourced in a shell, not executed directly"
unset CLUSTER'$local_cluster_index'_CIDR
export KUBECONFIG'$local_cluster_index'="'"$kube_config_path"'"
export K8S_ENV_NAME'$local_cluster_index'=packet
mkdir -p "'"$parent_path/private/kubeconfig"'"
' > "$parent_path"/private/current-env-$local_cluster_index.sh
chmod +x "$parent_path"/private/current-env-$local_cluster_index.sh

# ===== fetch kubeconfig =====

[ "$skip_fetch" = 'true' ] || source "$parent_path"/env--kubeconfig-packet.sh "$kube_config_path" msm-perf-test-$remote_cluster_index || return

source "$parent_path"/env-restore.sh split || return
