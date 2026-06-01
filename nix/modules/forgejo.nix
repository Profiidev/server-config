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
      Group = "forgejo-runner";

      StateDirectory = "forgejo-runner";
      WorkingDirectory = "/var/lib/forgejo-runner";

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

  networking.firewall.trustedInterfaces = [ "br-+" ];

  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNS = [ "10.43.0.10" ];
        Domains = [ "~cluster.local" ];
      };
    };
  };
}
