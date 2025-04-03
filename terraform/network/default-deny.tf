resource "kubectl_manifest" "default_deny" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: default-deny
spec:
  order: 100
  namespaceSelector: kubernetes.io/metadata.name not in {"calico-system", "kube-public", "kube-system", "tigera-operator"}
  types:
  - Ingress
  - Egress
  egress:
   # allow all namespaces to communicate to DNS pods
  - action: Allow
    protocol: UDP
    destination:
      selector: 'k8s-app == "kube-dns"'
      ports:
      - 53
  - action: Allow
    protocol: TCP
    destination:
      selector: 'k8s-app == "kube-dns"'
      ports:
      - 53
  YAML
}

resource "kubectl_manifest" "acme_allow" {
  yaml_body = <<YAML
apiVersion: crd.projectcalico.org/v1
kind: GlobalNetworkPolicy
metadata:
  name: acme-allow
spec:
  order: 90
  selector: acme.cert-manager.io/http01-solver == 'true'
  types:
  - Ingress
  ingress:
    - action: Allow
      protocol: TCP
      source:
        namespaceSelector: kubernetes.io/metadata.name == 'kube-system'
        selector: app.kubernetes.io/name == 'rke2-ingress-nginx'
  YAML
}
