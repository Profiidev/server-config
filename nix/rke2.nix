{ pkgs, ... }:

let
  pssFile = pkgs.writeText "rke2-pss-custom.yaml" ''
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
  '';

  configFile = pkgs.writeText "config.yaml" ''
    cni: calico
    profile: cis
    pod-security-admission-config-file: ${pssFile}
    etcd-expose-metrics: true
    kube-controller-manager-arg:
      - bind-address=0.0.0.0
    kube-scheduler-arg:
      - bind-address=0.0.0.0
    kube-proxy-arg:
      - metrics-bind-address=0.0.0.0
    kubelet-arg:
      - max-pods=200
    ingress-controller: traefik
  '';
in
{
  services.openiscsi = {
    enable = true;
    name = "iqn.2020-08.org.linux-iscsi.initiatorhost:example";
  };

  services.rke2 = {
    enable = true;

    configPath = configFile;
  };

  users.groups.etcd = { };
  users.users.etcd = {
    isSystemUser = true;
    createHome = false;
    description = "etcd user";
    group = "etcd";
  };
}
