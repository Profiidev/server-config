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

  # wait for ssh to be available
  until ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no {{USER}}@{{IP}} "echo SSH is available"; do
    sleep 5
  done

  just update-keys {{CONFIG}} {{IP}} {{USER}}

  echo "Installation complete. Rebuilding configuration on {{IP}}..."
  just rebuild {{CONFIG}} {{IP}} {{USER}} true
  echo "Rebuild complete. Copying kubeconfig from {{IP}}..."

  # Only if this is the master node
  if [[ "{{CONFIG}}" == "node1" ]]; then
    just copy-kubeconfig {{IP}} {{USER}}
    just update-token {{CONFIG}} {{IP}} {{USER}}
  fi

update-token CONFIG IP USER="root":
  #!/usr/bin/env bash
  echo "Installation complete. Fetching RKE2 token..."
  export TOKEN=$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no {{USER}}@{{IP}} "sudo cat /var/lib/rancher/rke2/server/node-token")
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

  git add {{secrets_path}}
  git add {{nix_path}}/.sops.yaml
  git commit -m "chore: update age key for {{CONFIG}}"

rebuild CONFIG IP USER="root" INSECURE_SSH="true":
  #!/usr/bin/env bash
  set -euo pipefail

  if [[ "{{INSECURE_SSH}}" == "true" ]]; then
    export NIX_SSHOPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
  fi

  nixos-rebuild switch --flake {{nix_path}}#{{CONFIG}} \
    --target-host {{USER}}@{{IP}} \
    --build-host {{USER}}@{{IP}}

rekey:
  cd {{nix_path}} && sops updatekeys -y {{secrets_path}}

edit-secrets:
  cd {{nix_path}} && EDITOR="nvim" sops {{secrets_path}}

set-rke2-token TOKEN:
  sops -i --set '["rke2_token"] "{{TOKEN}}"' {{secrets_path}}

copy-kubeconfig IP USER="root":
  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no {{USER}}@{{IP}}:/etc/rancher/rke2/rke2.yaml {{kubeconfig_path}}

copy-kubeconfig-fixed IP USER="root" NEW_IP="kubernetes.default.svc.cluster.local:443":
  just copy-kubeconfig {{IP}} {{USER}}
  sed -i 's|server: https://.*|server: https://{{NEW_IP}}|' {{kubeconfig_path}}

forgejo-image:
  nix build {{nix_path}}#nixosConfigurations.forgejo.config.system.build.diskoImagesScript --accept-flake-config && {{pwd}}/result && qemu-img convert -f raw -O qcow2 {{pwd}}/main.raw {{pwd}}/main.qcow2 && rm {{pwd}}/main.raw

forgejo-image-upload:
  #!/usr/bin/env bash
  kubectl -n kubevirt get dv nixos-forgejo > /dev/null 2>&1 && echo "DataVolume nixos-forgejo already exists, skipping upload" && exit 0 || true

  CMD="virtctl image-upload dv nixos-forgejo --size=3Gi --image-path={{pwd}}/main.qcow2 --access-mode=ReadWriteOnce -n kubevirt --uploadproxy-url=https://localhost:8443 --insecure"
  eval $CMD
  kubectl port-forward -n kubevirt svc/cdi-uploadproxy 8443:443 &
  PF_PID=$!
  trap "kill $PF_PID" EXIT
  sleep 5
  eval $CMD
