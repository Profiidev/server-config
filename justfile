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
  #!/usr/bin/env bash
  set -euo pipefail
  
  nix run github:nix-community/nixos-anywhere -- \
    --flake {{nix_path}}#{{CONFIG}}-minimal \
    --target-host {{USER}}@{{IP}} \
    --build-on remote

  just update-keys {{CONFIG}} {{IP}} {{USER}}

  # only if config is node1 (master)
  if [[ "{{CONFIG}}" == "node1" ]]; then
    just update-token {{CONFIG}} {{IP}} {{USER}}
  fi

  echo "Installation complete. Rebuilding configuration on {{IP}}..."
  just rebuild {{CONFIG}} {{IP}} {{USER}}
  echo "Rebuild complete. Copying kubeconfig from {{IP}}..."
  
  if [[ "{{CONFIG}}" == "node1" ]]; then
    just copy-kubeconfig {{IP}} {{USER}}
  fi

update-token CONFIG IP USER="root":
  echo "Installation complete. Fetching RKE2 token..."
  export TOKEN=$(ssh {{USER}}@{{IP}} "sudo cat /var/lib/rancher/rke2/server/node-token")
  echo "RKE2 token: $TOKEN"

  echo "Run 'just set-rke2-token $TOKEN' to set the token in sops.yaml"
  just set-rke2-token $TOKEN
  git add {{secrets_path}}
  git commit -m "chore: update RKE2 token"

update-keys CONFIG IP USER="root":
  #!/usr/bin/env bash
  set -euo pipefail
  
  echo "Generating age key based on ssh host key..."
  export SSH_KEY=$(ssh-keyscan -p 22 -t ssh-ed25519 {{IP}} 2>&1 | grep ssh-ed25519 | cut -f2- -d" ")
  export AGE_KEY=$(echo $SSH_KEY | ssh-to-age)
  echo "Generated age key: $AGE_KEY"

  echo "Updating .sops.yaml with the new age key..."
  if [[ -n $(yq ".keys.hosts[] | select(anchor == \"{{CONFIG}}\")" "{{nix_path}}/.sops.yaml") ]]; then
    yq -i "(.keys.hosts[] | select(anchor == \"{{CONFIG}}\")) = \"$AGE_KEY\"" "{{nix_path}}/.sops.yaml"
  else
    yq -i ".keys.hosts += [\"$AGE_KEY\"] | .keys.hosts[-1] anchor = \"{{CONFIG}}\"" "{{nix_path}}/.sops.yaml"
  fi

  if [[ -z $(yq ".creation_rules[0].key_groups[0].age[] | select(alias == \"{{CONFIG}}\")" "{{nix_path}}/.sops.yaml") ]]; then
    yq -i '.creation_rules[0].key_groups[0].age += ["'"{{CONFIG}}"'"]' {{nix_path}}/.sops.yaml
    yq -i '.creation_rules[0].key_groups[0].age[-1] alias = "'"{{CONFIG}}"'"' {{nix_path}}/.sops.yaml
  fi
  echo "Updated .sops.yaml with new age key for host {{IP}}"
  
  just rekey

  git add {{nix_path}}/.sops.yaml
  git commit -m "chore: update age key for {{CONFIG}}"

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
