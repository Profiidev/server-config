{ host, ... }:

{
  boot.loader.grub.enable = true;
  boot.loader.timeout = 0;

  networking.hostName = host;
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  services.timesyncd.enable = true;
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };
}
