{ pkgs, lib, ... }:

{
  systemd.services.forgejo-runner = {
    enable = true;
    description = "Forgejo Runner";

    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "docker.service"
    ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      HOME = "/var/lib/forgejo-runner";
    };
    path = with pkgs; [
      coreutils
    ];

    serviceConfig = {
      DynamicUser = true;
      User = "forgejo-runner";
      StateDirectory = "forgejo-runner";
      WorkingDirectory = "-/var/lib/forgejo-runner";

      Restart = "on-failure";
      RestartSec = 2;

      ExecStart = "${lib.getExe pkgs.forgejo-runner} daemon --config /mnt/forgejo/runner-config.yaml";
      SupplementaryGroups = [ "docker" ];
    };
  };

  fileSystems."/mnt/forgejo" = {
    device = "forgejo-secret";
    fsType = "virtiofs";
    options = [
      "defaults"
      "ro"
    ];
  };

  fileSystems."/var/lib" = {
    device = "runner-storage";
    fsType = "virtiofs";
    options = [
      "defaults"
      "rw"
    ];
  };

  networking.firewall.trustedInterfaces = [ "br-+" ];

  services.resolved = {
    domains = [ "~cluster.local" ];
  };
}
