# Server Config

## Setup

- create rke2 config `/etc/rancher/rke2/config.yaml`

  ```
  cni: calico
  profile: cis
  pod-security-admission-config-file: /etc/rancher/rke2/rke2-pss-custom.yaml
  ```

- create admission config `/etc/rancher/rke2/rke2-pss-custom.yaml`

  ```yaml
  apiVersion: apiserver.config.k8s.io/v1
  kind: AdmissionConfiguration
  plugins:
    - name: PodSecurity
      configuration:
        apiVersion: pod-security.admission.config.k8s.io/v1beta1
        kind: PodSecurityConfiguration
        defaults:
          enforce: "privileged"
          enforce-version: "latest"
        exemptions:
          usernames: []
          runtimeClasses: []
          namespaces: []
  ```

- install rke2

  ```
  curl -sfL https://get.rke2.io | sh -s - server
  systemctl enable rke2-server.service
  systemctl start rke2-server.service
  ```

- add kernel params

  ```
  cp -f /usr/local/share/rke2/rke2-cis-sysctl.conf /etc/sysctl.d/60-rke2-cis.conf
  systemctl restart systemd-sysctl
  sysctl -p /usr/local/share/rke2/rke2-cis-sysctl.conf
  ```

- Apply Terraform config
  ```
  terraform apply
  ```
