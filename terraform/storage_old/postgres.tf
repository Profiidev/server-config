resource "kubernetes_namespace" "everest_system_ns" {
  metadata {
    name = var.everest_system_ns
    labels = {
      "${var.secret_store_label.key}"    = var.secret_store_label.value
      "${var.oidc_access_label.key}"     = var.oidc_access_label.value
      "${var.cloudflare_cert_label.key}" = var.cloudflare_cert_label.value
      "${var.minio_access_label.key}"    = var.minio_access_label.value
    }
  }
}

resource "helm_release" "postgres" {
  name       = "postgres-ui"
  repository = "https://percona.github.io/percona-helm-charts"
  chart      = "everest"
  version    = "1.5.0"
  namespace  = var.everest_system_ns

  values = [templatefile("${path.module}/templates/postgres-ui.values.tftpl", {
  })]

  depends_on = [kubernetes_namespace.everest_system_ns]
}

resource "kubectl_manifest" "everest_system_egress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: everest-egress
  namespace: ${var.everest_system_ns}
spec:
  order: 10
  namespaceSelector: kubernetes.io/metadata.name == '${var.everest_system_ns}'
  types:
    - Egress
  egress:
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

  depends_on = [kubernetes_namespace.everest_system_ns]
}

resource "null_resource" "wait_for_everest_olm_ns" {
  provisioner "local-exec" {
    command = <<EOT
      until kubectl get namespace ${var.everest_olm_ns}; do
        echo "Waiting for namespace ${var.everest_olm_ns} ..."
        sleep 5
      done
    EOT
  }
}

resource "kubectl_manifest" "everest_np" {
  for_each = toset([var.everest_monitoring_ns, var.everest_olm_ns, var.everest_system_ns, var.everest_ns])

  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: everest-np
  namespace: ${each.value}
spec:
  order: 10
  selector: all()
  types:
    - Egress
    - Ingress
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
        namespaceSelector: kubernetes.io/metadata.name == '${var.everest_monitoring_ns}' || kubernetes.io/metadata.name == '${var.everest_olm_ns}' || kubernetes.io/metadata.name == '${var.everest_system_ns}' || kubernetes.io/metadata.name == '${var.everest_ns}'
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == '${var.everest_monitoring_ns}' || kubernetes.io/metadata.name == '${var.everest_olm_ns}' || kubernetes.io/metadata.name == '${var.everest_system_ns}' || kubernetes.io/metadata.name == '${var.everest_ns}'
  YAML

  depends_on = [null_resource.wait_for_everest_olm_ns]
}

resource "null_resource" "wait_for_everest_monitoring_ns" {
  provisioner "local-exec" {
    command = <<EOT
      until kubectl get namespace ${var.everest_monitoring_ns}; do
        echo "Waiting for namespace ${var.everest_monitoring_ns} ..."
        sleep 5
      done
    EOT
  }
}

resource "null_resource" "wait_for_everest_ns" {
  provisioner "local-exec" {
    command = <<EOT
      until kubectl get namespace ${var.everest_ns}; do
        echo "Waiting for namespace ${var.everest_ns} ..."
        sleep 5
      done
    EOT
  }
}

resource "null_resource" "everest_labels" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl label ns ${var.everest_ns} ${var.secret_store_label.key}=${var.secret_store_label.value}
      kubectl label ns ${var.everest_ns} ${var.minio_access_label.key}=${var.minio_access_label.value}
    EOT
  }
}

module "postgres_access" {
  source = "../modules/access-policy"

  namespace       = var.everest_ns
  namespace_label = var.postgres_access_label
  selector        = "app.kubernetes.io/name == 'percona-postgresql'"
  port            = 5432

  depends_on = [helm_release.postgres]
}

resource "kubernetes_ingress_v1" "postgres_ui_ingress" {
  metadata {
    name      = "vault-ui-ingress"
    namespace = var.everest_system_ns
    annotations = {
      "nginx.ingress.kubernetes.io/auth-tls-secret"        = "${var.everest_system_ns}/${var.cloudflare_ca_cert_var}",
      "nginx.ingress.kubernetes.io/auth-tls-verify-client" = "on"
    }
  }

  spec {
    ingress_class_name = var.ingress_class
    rule {
      host = "db.profidev.io"
      http {
        path {
          backend {
            service {
              name = "everest"
              port {
                number = 8080
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

  depends_on = [kubernetes_namespace.everest_system_ns]
}

resource "kubectl_manifest" "postgres_ui_ingress" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: postgres-ui-ingress
  namespace: ${var.everest_system_ns}
spec:
  order: 10
  selector: app.kubernetes.io/component == 'everest-server'
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
          - 8080
  YAML

  depends_on = [kubernetes_namespace.everest_system_ns]
}
