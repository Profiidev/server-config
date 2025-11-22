# Terraform Configuration

## Initial deployment order

1. crd: Install Custom Resource Definitions (CRDs) and monitoring tools.
2. storage: Set up storage solutions required for the cluster. (add cloudflare cert to vault)
3. network: Configure networking components and services.

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

db/minio_config:

- config.env: <MinIO configuration environment variables>

db/minio_metrics:

- token: <MinIO metrics token>

db/couchdb:

- cookie_auth: <CouchDB cookie authentication string>
- erlang_cookie: <CouchDB Erlang cookie>
- password: <CouchDB admin password>
- username: <CouchDB admin username>
