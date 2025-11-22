pwd := source_dir()
config_path := "terraform"
vars_path := pwd + "/vars.tfvars"
kubeconfig_path := pwd + "/terraform/rke2/data/kubeconfig"
nix_path := pwd + "/nix"

export KUBECONFIG := kubeconfig_path

init CONFIG:
  terraform -chdir={{config_path}}/{{CONFIG}} init

apply CONFIG:
  terraform -chdir={{config_path}}/{{CONFIG}} apply -var-file={{vars_path}} -auto-approve

destroy CONFIG:
  terraform -chdir={{config_path}}/{{CONFIG}} destroy -var-file={{vars_path}}

plan CONFIG:
  terraform -chdir={{config_path}}/{{CONFIG}} plan -var-file={{vars_path}}

install CONFIG IP USER="root":
  nix run github:nix-community/nixos-anywhere -- \
    --flake {{nix_path}}#{{CONFIG}} \
    --target-host {{USER}}@{{IP}} \
    --build-on remote

rebuild CONFIG IP USER="root":
  nixos-rebuild switch --flake {{nix_path}}#{{CONFIG}} \
    --target-host {{USER}}@{{IP}} \
    --build-host {{USER}}@{{IP}}
