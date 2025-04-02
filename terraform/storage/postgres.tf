resource "kubernetes_namespace" "everest_system_ns" {
  metadata {
    name = var.everest_system_ns
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

resource "kubectl_manifest" "everest_system_np" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: everest-np
  namespace: ${var.everest_system_ns}
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

  depends_on = [kubernetes_namespace.everest_system_ns]
}

resource "kubectl_manifest" "everest_system_gnp" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: everest-egress
spec:
  namespaceSelector: kubernetes.io/metadata.name == '${var.everest_system_ns}'
  types:
    - Egress
  egress:
    - action: Allow
      protocol: TCP
      destination:
        ports:
          - 443
        domains:
          - check.percona.com
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

resource "kubectl_manifest" "everest_olm_np" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: everest-np
  namespace: ${var.everest_olm_ns}
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

resource "kubectl_manifest" "everest_monitoring_np" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: everest-np
  namespace: ${var.everest_monitoring_ns}
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

  depends_on = [null_resource.wait_for_everest_monitoring_ns]
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

resource "kubectl_manifest" "everest_np" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: everest-np
  namespace: ${var.everest_ns}
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

  depends_on = [null_resource.wait_for_everest_ns]
}

resource "kubectl_manifest" "postgres_access" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: NetworkPolicy
metadata:
  name: postgres-access
  namespace: ${var.everest_ns}
spec:
  order: 10
  selector: app.kubernetes.io/name == 'percona-postgresql'
  types:
    - Ingress
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: ${var.postgres_access_label.key} == '${var.postgres_access_label.value}'
      destination:
        ports:
          - 5432
  YAML
}
