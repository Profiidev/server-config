resource "kubectl_manifest" "ingress_nginx_config" {
  yaml_body = <<YAML
apiVersion: helm.cattle.io/v1
kind: HelmChartConfig
metadata:
  name: rke2-ingress-nginx
  namespace: kube-system
spec:
  valuesContent: |-
    controller:
      image:
        PullPolicy: IfNotPresent
        repository: crowdsecurity/controller
        tag: v1.13.2
        digest: sha256:4575be24781cad35f8e58437db6a3f492df2a3167fed2b6759a6ff0dc3488d56
        registry: docker.io

      extraVolumes:
        - name: crowdsec-bouncer-plugin
          emptyDir: {}
      extraInitContainers:
        - name: init-clone-crowdsec-bouncer
          image: crowdsecurity/lua-bouncer-plugin
          imagePullPolicy: IfNotPresent
          env:
            - name: API_URL
              value: "http://crowdsec-service.crowdsec.svc.cluster.local:8080"
            - name: BOUNCER_CONFIG
              value: "/crowdsec/crowdsec-bouncer.conf"
            - name: CAPTCHA_PROVIDER
              value: "turnstile"
            - name: BAN_TEMPLATE_PATH
              value: "/etc/nginx/lua/plugins/crowdsec/templates/ban.html"
            - name: CAPTCHA_TEMPLATE_PATH
              value: "/etc/nginx/lua/plugins/crowdsec/templates/captcha.html"
              # optional appsec configuration
            - name: APPSEC_URL
              value: "http://crowdsec-appsec-service.crowdsec.svc.cluster.local:7422" # if using our helm chart with "crowdsec" release name, and running the appsec in the "crowdsec" namespace
            - name: APPSEC_FAILURE_ACTION
              value: "passthrough" # What to do if the appsec is down, optional
            - name: APPSEC_CONNECT_TIMEOUT # connection timeout to the appsec, in ms, optionial
              value: "100"
            - name: APPSEC_SEND_TIMEOUT # write timeout to the appsec, in ms, optional
              value: "100"
            - name: APPSEC_PROCESS_TIMEOUT # max processing duration of the request, in ms, optional
              value: "1000"
            - name: ALWAYS_SEND_TO_APPSEC
              value: "false"

            - name: API_KEY
              valueFrom:
                secretKeyRef:
                  name: nginx
                  key: API_KEY
            - name: SECRET_KEY
              valueFrom:
                secretKeyRef:
                  name: nginx
                  key: CAPTCHA_KEY
            - name: SITE_KEY
              valueFrom:
                secretKeyRef:
                  name: nginx
                  key: CAPTCHA_SITE_KEY
            
          command:
            [
              "sh",
              "-c",
              "sh /docker_start.sh; mkdir -p /lua_plugins/crowdsec/; cp -R /crowdsec/* /lua_plugins/crowdsec/",
            ]
          volumeMounts:
            - name: crowdsec-bouncer-plugin
              mountPath: /lua_plugins

      extraVolumeMounts:
        - name: crowdsec-bouncer-plugin
          mountPath: /etc/nginx/lua/plugins/crowdsec
          subPath: crowdsec

      config:
        plugins: "crowdsec"
        lua-shared-dicts: "crowdsec_cache: 50m"
        server-snippet: |
          lua_ssl_trusted_certificate "/etc/ssl/certs/ca-certificates.crt"; # If you want captcha support otherwise remove this line
          resolver local=on ipv6=off;

      ingressClassResource:
        name: ${var.ingress_class}
        enabled: true
        default: true
        controllerValue: "k8s.io/ingress-nginx"
        parameters: {}

      ingressClass: ${var.ingress_class}
      watchIngressWithoutClass: false

      networkPolicy:
        enabled: true
      hostNetwork: true
      metrics:
        enabled: true
        serviceMonitor:
          additionalLabels:
            release: prometheus
          enabled: true
    tcp:
      25: "stalwart/stalwart:25"
      587: "stalwart/stalwart:587"
      465: "stalwart/stalwart:465"
      993: "stalwart/stalwart:993"
  YAML
}

resource "null_resource" "everest_labels" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl label ns kube-system ${var.secret_store_label.key}=${var.secret_store_label.value}
    EOT
  }
}

resource "kubectl_manifest" "nginx_secrets" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: nginx
  namespace: kube-system
spec:
  refreshInterval: 15s
  secretStoreRef:
    name: ${var.cluster_secret_store}
    kind: ClusterSecretStore
  target:
    name: nginx
  dataFrom:
  - extract:
      key: certs/nginx
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