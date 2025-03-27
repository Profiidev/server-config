# Server Config

## Setup

1. Apply Terraform config
  ```
  terraform apply
  ```

- Get the cluster ca certificate and save it to certs/cluster ca.crt
  ```
  kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d |  kubectl exec -it --stdin=true --tty=true vault-0 -n vault -- vault kv put -mount="kv" "certs/cluster" ca.crt=-
  ```
