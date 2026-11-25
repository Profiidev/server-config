# network
cert_issuer_staging = "letsencrypt-staging"
cert_issuer_prod = "letsencrypt-prod"
ingress_class = "traefik"
cloudflare_ca_cert_var = "cloudflare-ca-cert"
cloudflare_cert_var = "cloudflare-cert"
cloudflare_buerger_ca_cert_var = "cloudflare-buerger-ca-cert"
cloudflare_buerger_cert_var = "cloudflare-buerger-cert"

# storage
storage_ns = "piraeus-datastore"
secrets_ns = "secrets"
cluster_secret_store = "vault"
ghcr_profidev = "ghcr-profidev"
storage_class = "linstor"

# tools
argo_ns = "argo"

# metrics
metrics_ns = "metrics"

smtp_username = "no-reply@profidev.io"
