# Terraform Configuration

## Initial deployment order

1. rke2: Deploy RKE2 Kubernetes cluster on the target machine.
2. crd: Install Custom Resource Definitions (CRDs) and monitoring tools.
3. storage: Set up storage solutions required for the cluster. (add cloudflare cert to vault)
4. network: Configure networking components and services.

## Required secrets in Vault

docker/ghcr:

- profidev: <GHCR_PAT>

certs/cert-manager:

- cloudflare: <Cloudflare API Token with DNS edit permissions>

certs/cloudflare:

- ca.crt: <Cloudflare Origin CA Certificate>
- tls.crt: <Cloudflare Origin CA TLS Certificate>
- tls.key: <Cloudflare Origin CA TLS Key>

certs/crowdsec:

- API_KEY: <CrowdSec API Key>

certs/nginx:

- API_KEY: <CrowdSec API Key>
- CAPTCHA_KEY: <Captcha Key for NGINX>
- CAPTCHA_SITE_KEY: <Captcha Site Key for NGINX>

db/minio_config:

- config.env: <MinIO configuration environment variables>

db/minio_metrics:

- token: <MinIO metrics token>

db/couchdb:

- cookie_auth: <CouchDB cookie authentication string>
- erlang_cookie: <CouchDB Erlang cookie>
- password: <CouchDB admin password>
- username: <CouchDB admin username>
