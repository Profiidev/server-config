resource "kubernetes_namespace" "crowdsec" {
  metadata {
    name = var.crowdsec_ns
  }
}

resource "random_password" "bouncer_key" {
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  special     = false
  length      = 32
}

# The agent is a DaemonSet with identical pod labels, so a Service can't target
# one node's agent. An init container stamps each agent pod with its node name
# (crowdsec-node=<node>) so the per-node Services below can select it.
resource "kubectl_manifest" "crowdsec_agent_sa" {
  yaml_body = <<YAML
apiVersion: v1
kind: ServiceAccount
metadata:
  name: crowdsec-agent
  namespace: ${var.crowdsec_ns}
YAML

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "kubectl_manifest" "crowdsec_agent_self_label" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: crowdsec-agent-self-label
  namespace: ${var.crowdsec_ns}
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "patch"]
YAML

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "kubectl_manifest" "crowdsec_agent_self_label_binding" {
  yaml_body = <<YAML
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: crowdsec-agent-self-label
  namespace: ${var.crowdsec_ns}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: crowdsec-agent-self-label
subjects:
  - kind: ServiceAccount
    name: crowdsec-agent
    namespace: ${var.crowdsec_ns}
YAML

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "helm_release" "crowdsec" {
  name       = "crowdsec"
  repository = "https://crowdsecurity.github.io/helm-charts"
  chart      = "crowdsec"
  namespace  = var.crowdsec_ns
  version    = "0.24.0"

  values = [
    templatefile("${path.module}/templates/crowdsec.values.tftpl", {
      traefik_bouncer_key = random_password.bouncer_key.result
    })
  ]

  depends_on = [
    kubernetes_namespace.crowdsec,
    kubectl_manifest.crowdsec_agent_sa,
    kubectl_manifest.crowdsec_agent_self_label_binding,
  ]
}

# One Service per node, each selecting only that node's agent pod (via the
# crowdsec-node label). Stable ClusterIP DNS, endpoints self-heal on pod restart.
# ponytail: assumes an agent runs on every node data.kubernetes_nodes returns; a
# tainted control-plane node with no agent would show as a down endpoint in the UI.
data "kubernetes_nodes" "all" {}

resource "kubectl_manifest" "crowdsec_agent_node_service" {
  for_each = toset([for n in data.kubernetes_nodes.all.nodes : n.metadata[0].name])

  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: crowdsec-agent-${each.key}
  namespace: ${var.crowdsec_ns}
spec:
  selector:
    k8s-app: crowdsec
    type: agent
    crowdsec-node: ${each.key}
  ports:
    - name: metrics
      port: 6060
      targetPort: 6060
YAML

  depends_on = [helm_release.crowdsec]
}

resource "kubectl_manifest" "crowdsec_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: crowdsec
  namespace: ${var.crowdsec_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: crowdsec
  dataFrom:
  - extract:
      key: certs/crowdsec
  YAML

  depends_on = [kubernetes_namespace.crowdsec]
}

module "external_np_crowdsec" {
  source = "../modules/external-np"

  namespace = var.crowdsec_ns

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "helm_release" "crowdsec_web_ui" {
  name       = "crowdsec-web-ui"
  repository = "https://zekker6.github.io/helm-charts"
  chart      = "crowdsec-web-ui"
  namespace  = var.crowdsec_ns
  version    = "0.50.0"

  values = [
    templatefile("${path.module}/templates/crowdsec-web-ui.values.tftpl", {
      ingress_class   = var.ingress_class
      namespace       = var.crowdsec_ns
      cloudflare_cert = var.cloudflare_cert_var
      agent_nodes     = sort([for n in data.kubernetes_nodes.all.nodes : n.metadata[0].name])
    })
  ]

  depends_on = [kubernetes_namespace.crowdsec]
}

resource "kubectl_manifest" "crowdsec_proxy_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: crowdsec-proxy
  namespace: ${var.crowdsec_ns}
spec:
  refreshInterval: 5m
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: crowdsec-proxy
  dataFrom:
  - extract:
      key: tools/crowdsec-proxy
  YAML
}

resource "kubectl_manifest" "crowdsec_oidc_middleware" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: crowdsec
  namespace: ${var.crowdsec_ns}
spec:
  plugin:
    traefik-oidc-auth:
      Secret: "urn:k8s:secret:crowdsec-proxy:secret"
      Provider:
        ClientId: "urn:k8s:secret:crowdsec-proxy:client-id"
        ClientSecret: "urn:k8s:secret:crowdsec-proxy:client-secret"
        Url: "https://profidev.io/api/oauth"
      Scopes:
        - "openid"
        - "profile"
        - "email"
  YAML
}

resource "kubectl_manifest" "crowdsec_tls_options" {
  yaml_body = <<YAML
apiVersion: traefik.io/v1alpha1
kind: TLSOption
metadata:
  name: crowdsec-tls-options
  namespace: ${var.crowdsec_ns}
spec:
  clientAuth:
    clientAuthType: RequireAndVerifyClientCert
    secretNames:
      - ${var.cloudflare_ca_cert_var}
  YAML
}
