resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.29.1"
  namespace  = var.secrets_ns

  values = [templatefile("${path.module}/templates/vault.values.tftpl", {
    cert_var      = var.vault_cert_var
    cert_prop     = var.vault_cert_prop
    storage_class = var.storage_class
  })]

  depends_on = [
    kubernetes_namespace.secrets_ns,
    kubernetes_secret_v1.vault_tls_secret,
  ]
}

resource "helm_release" "vault_auto_unseal" {
  name       = "vault-auto-unseal"
  repository = "https://profiidev.github.io/server-config"
  chart      = "vault-auto-unseal"
  version    = "0.1.9"
  namespace  = var.secrets_ns

  values = [templatefile("${path.module}/templates/vault-auto-unseal.values.tftpl", {
    key_1_var   = "vault-unseal-key-1"
    key_2_var   = "vault-unseal-key-2"
    key_3_var   = "vault-unseal-key-3"
    ca_cert_var = var.cluster_ca_cert_var
    secrets_ns  = var.secrets_ns
  })]

  depends_on = [
    kubernetes_namespace.secrets_ns,
    kubernetes_secret_v1.cluster_ca_cert_secret,
    kubernetes_secret_v1.vault_unseal_key
  ]
}


resource "null_resource" "vault_init" {
  triggers = {
    config_hash = sha256(jsonencode(var.secrets_ns))
  }

  provisioner "local-exec" {
    command = <<EOT
      while true; do
        output=$(kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault operator init -format=json | \
                 jq '{root_token} + ( .unseal_keys_b64 | to_entries | map({("key-\(.key+1)"): .value}) | add )' 2>&1)

        # Check if the output is empty
        if [ -z "$output" ]; then
          echo "Output is empty, retrying..."
        # Check if the output is valid JSON
        elif echo "$output" | jq empty > /dev/null 2>&1; then
          echo "$output" > ${path.module}/certs/keys.json
          echo "Vault operator init succeeded, keys saved to keys.json!"
          break
        else
          echo "Invalid JSON output, retrying..."
        fi

        sleep 5
      done
    EOT
  }

  depends_on = [helm_release.vault]
}

data "external" "vault_init_out" {
  program = ["bash", "-c", "cat ${path.module}/certs/keys.json"]

  depends_on = [null_resource.vault_init]
}

resource "kubernetes_secret_v1" "vault_unseal_key" {
  for_each = {
    for key in ["key-1", "key-2", "key-3", "key-4", "key-5"] :
    key => data.external.vault_init_out.result[key]
  }

  metadata {
    name      = "vault-unseal-${each.key}"
    namespace = var.secrets_ns
  }

  data = {
    key = each.value
  }

  type = "Opaque"
}

resource "null_resource" "vault_initial_unseal" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault operator unseal "${data.external.vault_init_out.result["key-1"]}"
      kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault operator unseal "${data.external.vault_init_out.result["key-2"]}"
      kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault operator unseal "${data.external.vault_init_out.result["key-3"]}"
      kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault login "${data.external.vault_init_out.result["root_token"]}"
    EOT
  }
}

resource "null_resource" "vault_init_kv" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl exec --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault secrets enable -path "kv" kv-v2
    EOT
  }

  depends_on = [null_resource.vault_initial_unseal]
}

resource "kubectl_manifest" "vault_k8s_api_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: k8s-api-egress
  namespace: ${var.secrets_ns}
spec:
  order: 10
  selector: app.kubernetes.io/name == 'vault-agent-injector'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        nets:
          - 194.164.200.60/32
        ports:
          - 6443
    - action: Allow
      protocol: TCP
      destination:
        notNets:
          - 10.0.0.0/8
          - 172.16.0.0/12
          - 192.168.0.0/16
        ports:
          - 443
  YAML

  depends_on = [kubernetes_namespace.secrets_ns]
}

resource "kubernetes_ingress_v1" "vault_ui_ingress" {
  metadata {
    name      = "vault-ui-ingress"
    namespace = var.secrets_ns
    annotations = {
      "nginx.ingress.kubernetes.io/auth-tls-secret"        = "${var.secrets_ns}/${var.cloudflare_ca_cert_var}",
      "nginx.ingress.kubernetes.io/auth-tls-verify-client" = "on"
      "nginx.ingress.kubernetes.io/backend-protocol"       = "HTTPS"
    }
  }

  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = "vault.profidev.io"
      http {
        path {
          backend {
            service {
              name = "vault-ui"
              port {
                number = 8200
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }

    tls {
      hosts       = ["*.profidev.io", "profidev.io"]
      secret_name = var.cloudflare_cert_var
    }
  }

  depends_on = [kubernetes_namespace.secrets_ns]
}

resource "kubectl_manifest" "vault_io_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: vault-ui-ingress
  namespace: ${var.secrets_ns}
spec:
  order: 10
  selector: app.kubernetes.io/name == 'vault'
  types:
    - Ingress
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == 'kube-system'
        selector: app.kubernetes.io/name == 'rke2-ingress-nginx'
      destination:
        ports:
          - 8200
  YAML

  depends_on = [kubernetes_namespace.secrets_ns]
}

/*
Role
vault write auth/oidc/role/default \
  bound_audiences="7f25d29e-ff95-4161-b95a-ad5d918bd85f" \
  allowed_redirect_uris="https://vault.profidev.io/ui/vault/auth/oidc/oidc/callback" \
  user_claim="email" \
  groups_claim="groups" \
  token_policies="default" \
  oidc_scopes="email,profile"
*/