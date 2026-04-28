{
  pkgs,
  host,
  lib,
  ...
}:

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
      - leader-elect-lease-duration=60s
      - leader-elect-renew-deadline=40s
      - leader-elect-retry-period=15s
    kube-scheduler-arg:
      - bind-address=0.0.0.0
      - leader-elect-lease-duration=60s
      - leader-elect-renew-deadline=40s
      - leader-elect-retry-period=15s
    etcd-arg:
      - leader-elect-lease-duration=60s
      - leader-elect-renew-deadline=40s
      - leader-elect-retry-period=15s
    kube-cloud-controller-manager-arg:
      - leader-elect-lease-duration=60s
      - leader-elect-renew-deadline=40s
      - leader-elect-retry-period=15s
    kube-proxy-arg:
      - metrics-bind-address=0.0.0.0
    kubelet-arg:
      - max-pods=200
    ingress-controller: traefik
    bind-address: ${host.ip}
    tls-san:
      - 10.0.0.1
      - 10.0.0.2
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
    token =
      lib.mkIf (!host.master)
        "";
    nodeIP = host.ip;
    #serverAddr = "https://10.0.0.1:9345";
    serverAddr = lib.mkIf (!host.master) "https://10.0.0.1:9345";
  };

  users.groups.etcd = { };
  users.users.etcd = {
    isSystemUser = true;
    createHome = false;
    description = "etcd user";
    group = "etcd";
  };

  systemd.tmpfiles.rules = [
    # Type | Path                                  | Mode | UID | GID | Age | Argument
    "d      /var/lib/rancher/rke2/server/db/etcd  0700   root  root  -     -"
    "d      /var/lib/longhorn                     0700   root  root  -     -"
    "h      /var/lib/rancher/rke2/server/db/etcd  -      -     -     -     +C"
    "h      /var/lib/longhorn                     0700   root  root  -     +C"
  ];
}
