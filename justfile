pwd := source_dir()
config_path := pwd + "/terraform"
vars_path := pwd + "/vars.tfvars"
secret_path := pwd + "/secrets.tfvars"
kubeconfig_path := pwd + "/kubeconfig"
nix_path := pwd + "/nix"
secrets_path := nix_path + "/sops.yaml"

export KUBECONFIG := kubeconfig_path

init CONFIG:
  terraform -chdir={{config_path}}/{{CONFIG}} init

apply CONFIG:
  terraform -chdir={{config_path}}/{{CONFIG}} apply -var-file={{vars_path}} -var-file={{secret_path}} -auto-approve

destroy CONFIG:
  terraform -chdir={{config_path}}/{{CONFIG}} destroy -var-file={{vars_path}} -var-file={{secret_path}}

plan CONFIG:
  terraform -chdir={{config_path}}/{{CONFIG}} plan -var-file={{vars_path}} -var-file={{secret_path}}

install CONFIG IP USER="root":
  nix run github:nix-community/nixos-anywhere -- \
    --flake {{nix_path}}#{{CONFIG}}-minimal \
    --target-host {{USER}}@{{IP}} \
    --build-on remote

  echo "Installation complete. Fetching RKE2 token..."
  TOKEN=$(ssh {{USER}}@{{IP}} "sudo cat /var/lib/rancher/rke2/server/node-token")
  echo "RKE2 token: $TOKEN"

  echo "Run 'just set-rke2-token $TOKEN' to set the token in sops.yaml"
  just set-rke2-token $TOKEN
  git add {{secrets_path}}
  git commit -m "chore: update RKE2 token"

  just rebuild {{CONFIG}} {{IP}} {{USER}}

rebuild CONFIG IP USER="root":
  nixos-rebuild switch --flake {{nix_path}}#{{CONFIG}} \
    --target-host {{USER}}@{{IP}} \
    --build-host {{USER}}@{{IP}}

rekey:
  cd {{nix_path}} && sops updatekeys -y {{secrets_path}}

edit-secrets:
  cd {{nix_path}} && EDITOR="nvim" sops {{secrets_path}}

set-rke2-token TOKEN:
  sops --set '["rke2_token"]' {{TOKEN}} {{secrets_path}}

copy-kubeconfig IP USER="root":
  scp {{USER}}@{{IP}}:/etc/rancher/rke2/rke2.yaml {{kubeconfig_path}}
  sed -i 's/127.0.0.1/{{IP}}/g' {{kubeconfig_path}}
