# Terraform Configuration

## Initial deployment order

1. crd: Install Custom Resource Definitions (CRDs) and monitoring tools.
2. storage: Set up storage solutions required for the cluster. (add cloudflare cert to vault)
3. network: Configure networking components and services.
4. db: Deploy database services. (create buckets and access keys after this)
5. tools: Install auxiliary tools and services.
6. metrics: Set up monitoring and metrics collection services.

## Required secrets in Vault

### After Storage setup (step 2)

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

db/postgres:

- password: <PostgreSQL admin password>
- username: <PostgreSQL admin username>

tools/argo:

- oidc.positron.clientSecret: <Positron OIDC client secret>
- webhook.github.secret: <GitHub webhook secret>

tools/coder:

- CODER_OIDC_CLIENT_ID: <Coder OIDC client ID>
- CODER_OIDC_CLIENT_SECRET: <Coder OIDC client secret>
- CODER_OIDC_EMAIL_DOMAIN: <Coder OIDC email domain>
- CODER_OIDC_ISSUER_URL: <Coder OIDC issuer URL>
- CODER_PG_CONNECTION_URL: <Coder PostgreSQL connection URL>

tools/tailscale:

- client_id: <Tailscale OAuth client ID>
- client_secret: <Tailscale OAuth client secret>

tools/longhorn:

- AWS_ACCESS_KEY_ID: <MinIO access key for Longhorn>
- AWS_ENDPOINTS: <MinIO service endpoint for Longhorn>
- AWS_SECRET_ACCESS_KEY: <MinIO secret key for Longhorn>

tools/longhorn-proxy:

- client-id: <OAuth2 Proxy client ID for Longhorn>
- client-secret: <OAuth2 Proxy client secret for Longhorn>
- cookie-secret: <OAuth2 Proxy cookie secret for Longhorn>

tools/auto-clean-bot:

- RUST_LOG: <Logging level for Auto Clean Bot>
- DISCORD_TOKEN: <Discord bot token for Auto Clean Bot>
- DB_URL: <Database connection URL for Auto Clean Bot>

### After DB setup (step 4)

apps/lgtm:

- GRAFANA_LOKI_S3_ACCESS_KEY: <MinIO access key for Grafana Loki>
- GRAFANA_LOKI_S3_SECRET_KEY: <MinIO secret key for Grafana Loki>
- GRAFANA_MIMIR_S3_ACCESS_KEY: <MinIO access key for Grafana Mimir>
- GRAFANA_MIMIR_S3_SECRET_KEY: <MinIO secret key for Grafana Mimir>
- GRAFANA_S3_ENDPOINT: <MinIO service endpoint>
- GRAFANA_TEMPO_S3_ACCESS_KEY: <MinIO access key for Grafana Tempo>
- GRAFANA_TEMPO_S3_SECRET_KEY: <MinIO secret key for Grafana Tempo>

apps/metrics:

- proxy: <Alertmanager Discord webhook proxy URL>
- url: <Alertmanager Discord webhook URL>

## S3 resources to create

### Buckets

- loki-admin
- loki-chunk
- loki-ruler
- mimir-alert
- mimir-blocks
- mimir-ruler
- tempo

### Access keys

- loki: Access to loki-admin, loki-chunk, loki-ruler buckets
- mimir: Access to mimir-alert, mimir-blocks, mimir-ruler buckets
- tempo: Access to tempo bucket
