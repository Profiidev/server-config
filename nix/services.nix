{ host, ... }:

{
  boot.loader.grub.enable = true;
  boot.loader.timeout = 0;

  networking.hostName = host;
  networking.networkmanager.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      6443 # Kubernetes API server
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
    };
  };

  services.fail2ban.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };
}
