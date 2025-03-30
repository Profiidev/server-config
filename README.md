# Server Config

## Setup

- kernel config `/etc/sysctl.d/90-kubelet.conf`

  ```
  vm.panic_on_oom=0
  vm.overcommit_memory=1
  kernel.panic=10
  kernel.panic_on_oops=1
  ```

  apply

  ```
  sysctl -p /etc/sysctl.d/90-kubelet.conf
  ```

- install k3s

  ```
  curl -sfL https://get.k3s.io | sh -s - server --secrets-encryption --disable=traefik --protect-kernel-defaults --cluster-init --flannel-backend=none --disable-network-policy
  ```

- Apply Terraform config
  ```
  terraform apply
  ```
