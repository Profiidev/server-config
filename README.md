# Server Config

## Setup

- Install K3s

  ```
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable=traefik"  sh -
  ```

- Apply Terraform config
  ```
  terraform apply
  ```
