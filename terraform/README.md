# Terraform Configuration

## Required secrets

secrets.tfvars file with the following variables:

```hcl
smtp_password = "<SMTP server password>"
apod_api_key = "<NASA APOD API Key>"
discord_token = "<Discord bot token for Auto Clean Bot>"
```

## Initial deployment order

1. crd: Install Custom Resource Definitions (CRDs) and monitoring tools.
2. storage: Set up storage solutions required for the cluster. (add cloudflare cert to vault)
3. network: Configure networking components and services.
4. db: Deploy database services. (create buckets, dbs and access keys after this)
5. tools: Install auxiliary tools and services.
6. metrics: Set up monitoring and metrics collection services.
7. apps: Deploy application services.
8. docker: Deploy Docker-related services and configurations.

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

tools/argo:

- oidc.positron.clientSecret: <Positron OIDC client secret>
- webhook.github.secret: <GitHub webhook secret>

tools/tailscale:

- client_id: <Tailscale OAuth client ID>
- client_secret: <Tailscale OAuth client secret>

tools/longhorn-proxy:

- client-id: <OAuth2 Proxy client ID for Longhorn>
- client-secret: <OAuth2 Proxy client secret for Longhorn>
- secret: <OAuth2 Proxy cookie secret for Longhorn>

apps/alloy-proxy:

- client-id: <OAuth2 Proxy client ID for Alloy>
- client-secret: <OAuth2 Proxy client secret for Alloy>
- secret: <OAuth2 Proxy cookie secret for Alloy>

tools/traefik-proxy:

- client-id: <OAuth2 Proxy client ID for Traefik>
- client-secret: <OAuth2 Proxy client secret for Traefik>
- secret: <OAuth2 Proxy cookie secret for Traefik>

tools/forgejo

- key: <Forgejo oidc client key>
- secret: <Forgejo oidc client secret>
- privateKey: <Forgejo ssh private key for git operations>

tools/radar:

- client-id: <OAuth2 Proxy client ID for Radar>
- client-secret: <OAuth2 Proxy client secret for Radar>
- secret: <OAuth2 Proxy cookie secret for Radar>

### After tools setup (step 5)

tools/forgejo-runner:

- runner-config.yaml: <Forgejo runner configuration>

## Databases to create

- positron
- nextcloud
- auto-clean-bot

## Additional setup steps

### Pterodactyl panel

create user:

```bash
docker exec -it panel php artisan p:user:make
```

copy ssl ca bundles to /mnt/ssl for wings because of symlinks

### Vault OIDC setup

role

```bash
vault write auth/oidc/role/default \
  bound_audiences="7f25d29e-ff95-4161-b95a-ad5d918bd85f" \
  allowed_redirect_uris="https://vault.profidev.io/ui/vault/auth/oidc/oidc/callback" \
  user_claim="email" \
  groups_claim="groups" \
  token_policies="default" \
  oidc_scopes="email,profile"
```

policy

```hcl
path "*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}
```

group:

name: Vault Admin
type: external
policies: admin
add alias: Vault Admin
