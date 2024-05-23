#!/usr/bin/env false "This script should be sourced in a shell, not executed directly"

alias "k1=kubectl --kubeconfig=$KUBECONFIG1"
alias "k2=kubectl --kubeconfig=$KUBECONFIG2"

shellname=$(ps -cp "$$" -o command="")
if [ "$shellname" = "bash" ]; then
    echo "set autocompletion for bash"
    source <(kubectl completion bash) || return || exit
    complete -o default -F __start_kubectl k1 || return || exit
    complete -o default -F __start_kubectl k2 || return || exit
elif [ "$shellname" = "zsh" ]; then
    echo "set autocompletion for zsh"
    source <(kubectl completion zsh) || return || exit
else
    echo "unsupported shell $shellname"
    return 1
fi
