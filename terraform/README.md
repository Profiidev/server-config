# Terraform Configuration

## Required secrets

secrets.tfvars file with the following variables:

```hcl
k8s_api = "<Kubernetes API server URL>"
email = "<Email address letsencrypt notifications will be sent to>"
smtp_password = "<SMTP server password>"
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

tools/longhorn-proxy:

- client-id: <OAuth2 Proxy client ID for Longhorn>
- client-secret: <OAuth2 Proxy client secret for Longhorn>
- cookie-secret: <OAuth2 Proxy cookie secret for Longhorn>

tools/auto-clean-bot:

- RUST_LOG: <Logging level for Auto Clean Bot>
- DISCORD_TOKEN: <Discord bot token for Auto Clean Bot>
- DB_URL: <Database connection URL for Auto Clean Bot>

apps/nextcloud:

- collabora-password: <Collabora Online admin password>
- collabora-username: <Collabora Online admin username>
- db-host: <Nextcloud database host>
- db-name: <Nextcloud database name>
- db-password: <Nextcloud database password>
- db-username: <Nextcloud database username>
- password: <Nextcloud admin password>
- smtp-host: <SMTP server host>
- smtp-password: <SMTP server password>
- smtp-username: <SMTP server port>
- username: <Nextcloud admin username>

apps/positron:

- APOD_API_KEY: <NASA APOD API Key>
- ASSETLINKS: <Positron Android Asset Links JSON content>
- AUTH_ISSUER: <OIDC issuer URL>
- AUTH_JWT_EXPIRATION: <JWT expiration duration>
- AUTH_JWT_EXPIRATION_SHORT: <Short JWT expiration duration>
- AUTH_PEPPER: <Authentication pepper string>
- CORS_ORIGIN: <CORS allowed origins>
- CORS_ORIGIN_REGEX: <CORS allowed origin regex patterns>
- DB_URL: <Database connection URL>
- FRONTEND_URL: <Positron frontend URL>
- LOG_LEVEL: <Logging level>
- NATS_UPDATE_SUBJECT: <NATS subject for updates>
- NATS_URL: <NATS server URL>
- OIDC_BACKEND_INTERNAL: <Internal OIDC provider URL>
- OIDC_BACKEND_URL: <Public OIDC provider URL>
- OIDC_ISSUER: <OIDC issuer URL>
- RUST_LOG: <Rust logging configuration>
- S3_ACCESS_KEY: <MinIO access key for Positron>
- S3_BUCKET: <MinIO bucket name for Positron>
- S3_HOST: <MinIO service endpoint>
- S3_KEY_ID: <MinIO access key ID for Positron
- S3_REGION: <MinIO region for Positron>
- SMTP_DOMAIN: <SMTP server domain>
- SMTP_PASSWORD: <SMTP server password>
- SMTP_SENDER_EMAIL: <SMTP sender email>
- SMTP_SENDER_NAME: <SMTP sender name>
- SMTP_SITE_LINK: <SMTP site link>
- SMTP_USERNAME: <SMTP server username>
- WEBAUTHN_ADDITIONAL_ORIGINS: <WebAuthn additional origins>
- WEBAUTHN_ID: <WebAuthn RPID>
- WEBAUTHN_NAME: <WebAuthn application name>
- WEBAUTHN_ORIGIN: <WebAuthn allowed origins>

apps/proton:

- CORS_ORIGIN: <CORS allowed origins>
- RUST_LOG: <Rust logging configuration>

apps/charm:

- CORS_ORIGIN: <CORS allowed origins>
- DB_URL: <Database connection URL>
- RUST_LOG: <Rust logging configuration>
- DB_LOGGING: <Database logging level>

### After DB setup (step 4)

apps/lgtm:

- GRAFANA_LOKI_S3_ACCESS_KEY: <MinIO access key for Grafana Loki>
- GRAFANA_LOKI_S3_SECRET_KEY: <MinIO secret key for Grafana Loki>
- GRAFANA_MIMIR_S3_ACCESS_KEY: <MinIO access key for Grafana Mimir>
- GRAFANA_MIMIR_S3_SECRET_KEY: <MinIO secret key for Grafana Mimir>
- GRAFANA_S3_ENDPOINT: <MinIO service endpoint>
- GRAFANA_TEMPO_S3_ACCESS_KEY: <MinIO access key for Grafana Tempo>
- GRAFANA_TEMPO_S3_SECRET_KEY: <MinIO secret key for Grafana Tempo>

apps/alert-bot:

- proxy: <Alertmanager Discord webhook proxy URL>
- url: <Alertmanager Discord webhook URL>

tools/longhorn:

- AWS_ACCESS_KEY_ID: <MinIO access key for Longhorn>
- AWS_ENDPOINTS: <MinIO service endpoint for Longhorn>
- AWS_SECRET_ACCESS_KEY: <MinIO secret key for Longhorn>

## S3 resources to create

### Buckets

- loki-admin
- loki-chunk
- loki-ruler
- mimir-alert
- mimir-blocks
- mimir-ruler
- tempo
- longhorn
- positron

### Access keys

- loki: Access to loki-admin, loki-chunk, loki-ruler buckets
- mimir: Access to mimir-alert, mimir-blocks, mimir-ruler buckets
- tempo: Access to tempo bucket
- longhorn: Access to longhorn bucket
- positron: Access to positron bucket

## Databases to create

- positron
- nextcloud
- coder
- charm
- auto-clean-bot

## Additional setup steps

### Pterodactyl panel

create user:

```bash
docker exec -it panel php artisan p:user:make
```

longhorn backup

vault oidc
docker
alerts
traefik metrics endpoints 80
rustfs ingress