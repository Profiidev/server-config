{ host, lib, ... }:

{
  boot.loader.grub.enable = true;
  boot.loader.grub.configurationLimit = lib.mkDefault 5;

  boot.initrd.systemd.enable = true;
  environment.ldso32 = null;
  boot.tmp.cleanOnBoot = lib.mkDefault true;

  networking.firewall.logRefusedConnections = lib.mkDefault false;
  networking.useNetworkd = lib.mkDefault true;
  networking.hostName = host.name;

  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.network.wait-online.enable = false;
  systemd.services.systemd-networkd.stopIfChanged = false;
  systemd.services.systemd-resolved.stopIfChanged = false;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      6443 # Kubernetes API server
      9345 # RKE2 server
      5473 # calico
      2379 # etcd server client API
      2380 # etcd server peer API
      2222 # SSH
      593
      594
    ];
  };

  services.timesyncd.enable = true;
  services.openssh = {
    enable = true;
    openFirewall = true;

    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      X11Forwarding = false;
      KbdInteractiveAuthentication = false;
      UseDns = false;
      StreamLocalBindUnlink = true;
    };
  };

  services.fail2ban.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  systemd = {
    enableEmergencyMode = false;
    settings.Manager = {
      RuntimeWatchdogSec = lib.mkDefault "15s";
      RebootWatchdogSec = lib.mkDefault "30s";
      KExecWatchdogSec = lib.mkDefault "1m";
    };
  };
}
