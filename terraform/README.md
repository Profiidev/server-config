# Terraform Configuration

## Required secrets

secrets.tfvars file with the following variables:

```hcl
smtp_password = "<SMTP server password>"
apod_api_key = "<NASA APOD API Key>"
discord_token = "<Discord bot token for Auto Clean Bot>"
discord_alert_webhook = "<Discord webhook URL for alerts>"
github_webhook = "<GitHub webhook secret for Argo CD>"
```

## Initial deployment order

1. crd: Install Custom Resource Definitions (CRDs) and monitoring tools.
2. storage: Set up storage solutions required for the cluster. (add cloudflare cert to vault)
3. network: Configure networking components and services.
4. db: Deploy database services. (create buckets, dbs and access keys after this)
5. tools: Install auxiliary tools and services.
6. metrics: Set up monitoring and metrics collection services.
7. sso: Configure Single Sign-On (SSO) services and authentication mechanisms.
8. apps: Deploy application services.

## Destory

Confirm flags: 2. storage: Confirm longhorn deletion 5. tools: Remove finalizer from cdi resource

Remove resource modules (app-oidc, app-resources):

1. Set `enabled = false` in the respective module blocks in terraform
2. Run `terraform apply` to update the infrastructure and remove the resources associated with these modules
3. After the resources are removed, you can optionally delete the module blocks from terraform if they are no longer needed.

## Required secrets in Vault

### After Storage setup (step 2)

docker/ghcr:

- profidev: <GHCR_PAT>

certs/cert-manager:

- cloudflare: <Cloudflare API Token with DNS edit permissions> (token requires ip whitelist)

certs/cloudflare:

- ca.crt: <Cloudflare Origin CA Certificate>
- tls.crt: <Cloudflare Origin CA TLS Certificate>
- tls.key: <Cloudflare Origin CA TLS Key>

certs/crowdsec:

- API_KEY: <CrowdSec API Key>

tools/tailscale:

- client_id: <Tailscale OAuth client ID>
- client_secret: <Tailscale OAuth client secret>

### After apps setup (step 8)

tools/forgejo-runner:

- runner-config.yaml: <Forgejo runner configuration>

base config:

```yaml
server:
  connections:
    forgejo:
      url: https://git.profidev.io/
      token: <token>
      uuid: <uuid>
runner:
  name: node1
  labels:
    - node-22:docker://node22-bookworm
    - nixos-latest:docker://nixos/nix
    - ubuntu-latest:docker://node:16-bullseye
```

## Additional setup steps

### SSO Client

- Cloudflare
- Tailscale
