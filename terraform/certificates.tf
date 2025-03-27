variable "cluster_ca_cert_var" {
  type    = string
  default = "cluster-ca-cert"
}

variable "cloudflare_ca_cert_var" {
  type    = string
  default = "cloudflare-ca-cert"
}

variable "cloudflare_cert_var" {
  type    = string
  default = "cloudflare-cert"
}

variable "cloudflare_cert_label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "cloudflare-cert-secret"
    value = "true"
  }
}

variable "cluster_ca_cert_label" {
  type = object({
    key   = string
    value = string
  })
  default = {
    key   = "cluster-ca-cert"
    value = "true"
  }
}

variable "cert_issuer_staging" {
  type    = string
  default = "letsencrypt-staging"
}

variable "cert_issuer_prod" {
  type    = string
  default = "letsencrypt-prod"
}

variable "cert_ns" {
  description = "Certificate Manager Namespace"
  type        = string
  default     = "cert-system"
}

resource "kubernetes_namespace" "cert_ns" {
  metadata {
    name = var.cert_ns
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.17.0"
  namespace  = var.cert_ns
  skip_crds  = true

  values = [templatefile("${path.module}/../helm/cert-manager.values.tftpl", {})]

  depends_on = [kubernetes_namespace.cert_ns]
}

data "external" "cluster_ca_cert" {
  program = ["bash", "-c", <<EOT
    kubectl config view --raw --minify --flatten \
     -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d |\
     jq -R -s '{ca: .}'
  EOT
  ]
}

resource "kubernetes_manifest" "cert_issuer" {
  for_each = tomap({
    staging = "https://acme-staging-v02.api.letsencrypt.org/directory"
    prod    = "https://acme-v02.api.letsencrypt.org/directory"
  })

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = each.key == "prod" ? var.cert_issuer_prod : var.cert_issuer_staging
    }
    spec = {
      acme = {
        email  = var.email
        server = each.value
        privateKeySecretRef = {
          name = "letsencrypt-${each.key}-issuer-account-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                ingressClassName = var.ingress_class
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "cloudflare_cert" {
  for_each = tomap({
    "${var.cloudflare_cert_var}"    = ["tls.crt", "tls.key"]
    "${var.cloudflare_ca_cert_var}" = ["ca.crt"]
  })

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterExternalSecret"
    metadata = {
      name = each.key
    }
    spec = {
      externalSecretName = each.key
      namespaceSelectors = [
        {
          matchLabels = {
            "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
          }
        }
      ]
      refreshTime = "15s"

      externalSecretSpec = {
        target = {
          name = each.key
        }
        refreshInterval = "15s"
        secretStoreRef = {
          name = var.cluster_secret_store
          kind = "ClusterSecretStore"
        }
        data = [
          for value in each.value : {
            secretKey = value
            remoteRef = {
              key      = "certs/cloudflare"
              property = value
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.external_secrets]
}

resource "kubernetes_manifest" "cluster_ca_cert" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterExternalSecret"
    metadata = {
      name = var.cluster_ca_cert_var
    }
    spec = {
      externalSecretName = var.cluster_ca_cert_var
      namespaceSelectors = [
        {
          matchLabels = {
            "${var.cluster_ca_cert_label.key}" = var.cluster_ca_cert_label.value
          }
        }
      ]
      refreshTime = "15s"

      externalSecretSpec = {
        target = {
          name = var.cluster_ca_cert_var
        }
        refreshInterval = "15s"
        secretStoreRef = {
          name = var.cluster_secret_store
          kind = "ClusterSecretStore"
        }
        data = [
          {
            secretKey = "ca.crt"
            remoteRef = {
              key      = "certs/cluster"
              property = "ca.crt"
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.external_secrets]
}

resource "null_resource" "vault_cluster_ca_cert" {
  provisioner "local-exec" {
    command = <<-EOT
      kubectl exec -it --stdin=true --tty=true vault-0 -n ${var.secrets_ns} -- vault kv put -mount="kv" "certs/cluster" ca.crt="${data.external.cluster_ca_cert.result["ca"]}"
    EOT
  }

  depends_on = [null_resource.vault_initial_unseal]
}
