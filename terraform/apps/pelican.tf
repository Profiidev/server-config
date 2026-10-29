resource "kubernetes_namespace" "pelican" {
  metadata {
    name = var.pelican_ns
  }
}

resource "kubernetes_namespace" "pelican_system" {
  metadata {
    name = var.pelican_system_ns
  }
}

resource "kubectl_manifest" "pelican_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: pelican
  namespace: ${var.pelican_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: pelican
  dataFrom:
  - extract:
      key: apps/pelican
  YAML

  depends_on = [kubernetes_namespace.pelican]
}

resource "kubectl_manifest" "pelican_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: pelican-tls-options
  namespace: ${var.pelican_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML

  depends_on = [kubernetes_namespace.pelican]
}

# Positron, plugin hub, composer packages and the wings gateway are all public HTTPS
module "pelican_egress" {
  source = "../modules/external-np"

  namespace = var.pelican_ns

  depends_on = [kubernetes_namespace.pelican]
}

# The gateway calls the Panel through its public URL
module "pelican_system_egress" {
  source = "../modules/external-np"

  namespace = var.pelican_system_ns

  depends_on = [kubernetes_namespace.pelican_system]
}

resource "helm_release" "pelican_panel" {
  name       = "pelican-panel"
  repository = "oci://ghcr.io/claiyc/pelican-k8s/charts"
  chart      = "pelican-panel"
  version    = "0.1.4"
  namespace  = var.pelican_ns

  values = [templatefile("${path.module}/templates/pelican-panel.values.tftpl", {
    ingress_class       = var.ingress_class
    cloudflare_cert_var = var.cloudflare_cert_var
    storage_class       = var.storage_class
    namespace           = var.pelican_ns
  })]

  depends_on = [kubectl_manifest.pelican_secrets, module.pelican_egress]
}

# One-time Panel bootstrap: Positron login, break-glass admin and the node the gateway serves.
# Reads secrets from the synced k8s Secret so they never land in Terraform state.
resource "terraform_data" "pelican_setup" {
  input = {
    ns        = var.pelican_ns
    system_ns = var.pelican_system_ns
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      EXEC="kubectl exec -n ${self.input.ns} deploy/pelican-panel -c panel --"
      secret() { kubectl get secret pelican -n ${self.input.ns} -o jsonpath="{.data.$1}" | base64 -d; }

      $EXEC php artisan tinker --execute='app(App\Services\Helpers\PluginService::class)->downloadPluginFromUrl("https://hub.pelican.dev/plugins/generic-oidc-providers/download/276/generic-oidc-providers.zip", "generic-oidc-providers", "49ffce269cc51c4f3aaedeeb8bff9f3153443654d7b803415aaac53bf64254b0");'
      $EXEC php artisan p:plugin:install generic-oidc-providers

      $EXEC env CLIENT_ID="$(secret OIDC_CLIENT_ID)" CLIENT_SECRET="$(secret OIDC_CLIENT_SECRET)" php artisan tinker --execute='Boy132\GenericOIDCProviders\Models\GenericOIDCProvider::forceCreate([
        "id" => "positron",
        "display_name" => "Positron",
        "base_url" => "https://profidev.io/api/oauth",
        "client_id" => getenv("CLIENT_ID"),
        "client_secret" => getenv("CLIENT_SECRET"),
        "create_missing_users" => true,
        "link_missing_users" => true,
        "verify_jwt" => false,
        "use_pkce" => true,
      ]);'

      $EXEC php artisan p:user:make --admin=1 --email=admin@profidev.io --username=admin --password="$(secret ADMIN_PASSWORD)"
      # Positron login links to this user by email; promote it if a login already created it
      $EXEC php artisan tinker --execute='(App\Models\User::firstWhere("email", "mail@profidev.io")
        ?? app(App\Services\Users\UserCreationService::class)->handle(["email" => "mail@profidev.io", "username" => "profidev"]))
        ->syncRoles(App\Models\Role::getRootAdmin());'

      NODE_ID=$($EXEC php artisan p:node:make --name=kubernetes --description=pelican-k8s \
        --fqdn=wings.profidev.io --scheme=https --proxy=1 --public=1 --maintenance=0 \
        --maxMemory=0 --overallocateMemory=-1 --maxDisk=0 --overallocateDisk=-1 --maxCpu=0 --overallocateCpu=-1 \
        --uploadSize=100 --daemonListeningPort=8080 --daemonConnectingPort=443 \
        --daemonSFTPPort=2022 --daemonSFTPAlias=cluster.profidev.io --daemonBase=/var/lib/pelican/volumes \
        | grep -oP 'id of \K\d+')
      CONFIG=$($EXEC php artisan p:node:configuration "$NODE_ID" --format=json)

      kubectl create secret generic pelican-node -n ${self.input.system_ns} \
        --from-literal=token_id="$(echo "$CONFIG" | jq -r .token_id)" \
        --from-literal=token="$(echo "$CONFIG" | jq -r .token)"
    EOT
  }

  depends_on = [helm_release.pelican_panel, kubernetes_namespace.pelican_system]
}

resource "helm_release" "pelican_k8s" {
  name       = "pelican-k8s"
  repository = "oci://ghcr.io/claiyc/pelican-k8s/charts"
  chart      = "pelican-k8s"
  version    = "2.2.1"
  namespace  = var.pelican_system_ns

  values = [templatefile("${path.module}/templates/pelican-k8s.values.tftpl", {
    ingress_class  = var.ingress_class
    cluster_issuer = var.cert_issuer_prod
    storage_class  = var.storage_class
  })]

  depends_on = [terraform_data.pelican_setup, module.pelican_system_egress]
}

resource "kubectl_manifest" "pelican_sftp_gateway" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: pelican-sftp
  namespace: ${var.pelican_system_ns}
spec:
  gatewayClassName: traefik
  listeners:
    - name: sftp
      protocol: TCP
      port: 2022
  YAML

  depends_on = [kubernetes_namespace.pelican_system]
}

resource "kubectl_manifest" "pelican_sftp_route" {
  yaml_body = <<YAML
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TCPRoute
metadata:
  name: pelican-sftp
  namespace: ${var.pelican_system_ns}
spec:
  parentRefs:
    - name: pelican-sftp
      sectionName: sftp
  rules:
    - backendRefs:
        - name: pelican-k8s-gateway-sftp
          port: 2022
  YAML

  depends_on = [kubectl_manifest.pelican_sftp_gateway]
}
