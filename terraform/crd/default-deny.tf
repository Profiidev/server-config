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
  # allow all pods to communicate within private IP ranges
  - action: Allow
    protocol: TCP
    destination:
      nets:
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16
  - action: Allow
    protocol: UDP
    destination:
      nets:
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16
  ingress:
  # allow all pods to communicate within private IP ranges
  - action: Allow
    protocol: TCP
    source:
      nets:
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16 
  - action: Allow
    protocol: UDP
    source:
      nets:
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16
  YAML
}
