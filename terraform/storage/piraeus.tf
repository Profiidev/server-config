resource "kubernetes_namespace" "storage" {
  metadata {
    name = var.storage_ns
  }
}

resource "helm_release" "piraeus_operator" {
  name       = "piraeus-operator"
  repository = "oci://ghcr.io/piraeusdatastore/piraeus-operator"
  chart      = "piraeus"
  version    = "2.12.1"
  namespace  = kubernetes_namespace.storage.metadata[0].name

  set = [{
    name  = "installCRDs"
    value = "true"
  }]
}

# Encrypts LINSTOR secrets (S3 remote credentials). Losing it makes backups unreadable: back it up from tf state.
# Not in Vault, because Vault itself runs on LINSTOR volumes.
resource "random_password" "linstor_passphrase" {
  length  = 48
  special = false
}

resource "kubernetes_secret_v1" "linstor_passphrase" {
  metadata {
    name      = "linstor-passphrase"
    namespace = kubernetes_namespace.storage.metadata[0].name
  }
  data = {
    MASTER_PASSPHRASE = random_password.linstor_passphrase.result
  }
}

# mTLS between controller and satellites (port 3367), own CA so it doesn't depend on cert-manager (network stage)
resource "tls_private_key" "linstor_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "linstor_ca" {
  private_key_pem       = tls_private_key.linstor_ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 87600
  allowed_uses          = ["cert_signing", "crl_signing"]

  subject {
    common_name = "linstor-internal-ca"
  }
}

locals {
  linstor_tls = {
    controller = ["linstor-controller", "linstor-controller.${var.storage_ns}.svc"]
    satellite  = ["node1", "node2", "node3"]
  }
}

resource "tls_private_key" "linstor" {
  for_each    = local.linstor_tls
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "linstor" {
  for_each        = local.linstor_tls
  private_key_pem = tls_private_key.linstor[each.key].private_key_pem
  dns_names       = each.value

  subject {
    common_name = "linstor-${each.key}"
  }
}

resource "tls_locally_signed_cert" "linstor" {
  for_each              = local.linstor_tls
  cert_request_pem      = tls_cert_request.linstor[each.key].cert_request_pem
  ca_private_key_pem    = tls_private_key.linstor_ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.linstor_ca.cert_pem
  validity_period_hours = 87600
  allowed_uses          = ["digital_signature", "key_encipherment", "server_auth", "client_auth"]
}

resource "kubernetes_secret_v1" "linstor_tls" {
  for_each = local.linstor_tls

  metadata {
    name      = "linstor-${each.key}-internal-tls"
    namespace = kubernetes_namespace.storage.metadata[0].name
  }
  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = tls_locally_signed_cert.linstor[each.key].cert_pem
    "tls.key" = tls_private_key.linstor[each.key].private_key_pem
    "ca.crt"  = tls_self_signed_cert.linstor_ca.cert_pem
  }
}

resource "kubectl_manifest" "linstor_cluster" {
  yaml_body = <<YAML
apiVersion: piraeus.io/v1
kind: LinstorCluster
metadata:
  name: linstorcluster
spec:
  linstorPassphraseSecret: ${kubernetes_secret_v1.linstor_passphrase.metadata[0].name}
  internalTLS:
    secretName: ${kubernetes_secret_v1.linstor_tls["controller"].metadata[0].name}
  # NFS export for RWX filesystem volumes, not used
  nfsServer:
    enabled: false
  controller:
    podTemplate:
      spec:
        containers:
          - name: linstor-controller
            env:
              # image default -Xms256M -Xmx8G with G1; JAVA_OPTS comes after it and wins
              - name: JAVA_OPTS
                value: "-Xmx512M -XX:+UseSerialGC"
YAML

  depends_on = [helm_release.piraeus_operator]
}

resource "kubectl_manifest" "linstor_satellites" {
  yaml_body = <<YAML
apiVersion: piraeus.io/v1
kind: LinstorSatelliteConfiguration
metadata:
  name: satellites
spec:
  internalTLS:
    secretName: ${kubernetes_secret_v1.linstor_tls["satellite"].metadata[0].name}
  storagePools:
    # VG + thin pool created by disko (nix/modules/disko-config.nix)
    - name: thin
      lvmThinPool:
        volumeGroup: linstor_vg
        thinPool: thin
  podTemplate:
    spec:
      # DRBD keeps the node IP across satellite restarts; ports opened in nix/modules/piraeus.nix
      hostNetwork: true
      # S3 shipping runs in the satellite: resolve garage.<ns>.svc via cluster DNS, not the node's resolver
      dnsPolicy: ClusterFirstWithHostNet
      containers:
        - name: linstor-satellite
          env:
            # image default -Xms32M -Xmx2G with G1; JAVA_OPTS comes after it and wins
            - name: JAVA_OPTS
              value: "-Xmx256M -XX:+UseSerialGC"
      initContainers:
        # DRBD module comes from the host (nix/modules/piraeus.nix)
        - name: drbd-module-loader
          $patch: delete
YAML

  depends_on = [helm_release.piraeus_operator]
}

locals {
  linstor_storage_classes = {
    (var.storage_class) = {}
    # Postgres; resource group "backup" ships to Garage S3 (schedule set up in db stage)
    "${var.storage_class}-backup" = {
      "linstor.csi.linbit.com/resourceGroup" = "backup"
    }
    # KubeVirt RWX Block live migration needs DRBD dual primary
    "${var.storage_class}-vm" = {
      "linstor.csi.linbit.com/resourceGroup"                                = "vm"
      "property.linstor.csi.linbit.com/DrbdOptions/Net/allow-two-primaries" = "yes"
    }
  }
}

resource "kubernetes_storage_class_v1" "linstor" {
  for_each = local.linstor_storage_classes

  metadata {
    name = each.key
    annotations = merge(
      each.key == var.storage_class ? { "storageclass.kubernetes.io/is-default-class" = "true" } : {},
      each.key == "${var.storage_class}-vm" ? { "cdi.kubevirt.io/clone-strategy" = "csi-clone" } : {},
    )
  }

  storage_provisioner    = "linstor.csi.linbit.com"
  allow_volume_expansion = true
  volume_binding_mode    = "WaitForFirstConsumer"
  reclaim_policy         = "Delete"
  mount_options          = ["discard"]

  parameters = merge({
    "linstor.csi.linbit.com/storagePool"    = "thin"
    "linstor.csi.linbit.com/placementCount" = "3"
    "csi.storage.k8s.io/fstype"             = "ext4"
  }, each.value)

  depends_on = [kubectl_manifest.linstor_cluster]
}

resource "kubectl_manifest" "linstor_controller_monitor" {
  yaml_body = <<YAML
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: linstor-controller
  namespace: ${kubernetes_namespace.storage.metadata[0].name}
spec:
  endpoints:
    - port: api
      scheme: http
      path: /metrics
  selector:
    matchLabels:
      app.kubernetes.io/component: linstor-controller
YAML
}

resource "kubectl_manifest" "linstor_satellite_monitor" {
  yaml_body = <<YAML
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: linstor-satellite
  namespace: ${kubernetes_namespace.storage.metadata[0].name}
spec:
  podMetricsEndpoints:
    - port: prometheus
      scheme: http
      relabelings:
        - action: replace
          sourceLabels:
            - __meta_kubernetes_pod_node_name
          targetLabel: node
  selector:
    matchLabels:
      app.kubernetes.io/component: linstor-satellite
YAML
}
