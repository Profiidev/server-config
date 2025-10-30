{
  enterShell = ''
    export KUBECONFIG="$DEVENV_ROOT/terraform/rke2/data/kubeconfig"
    export KUBE_CONFIG_PATH=$KUBECONFIG
  '';
}
