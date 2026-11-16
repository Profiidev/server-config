{ host, lib, pkgs, ... }:

let
  # 1-based node index from the private IP, used to stagger heavy maintenance across nodes
  idx = lib.toInt (lib.last (lib.splitString "." host.ip));
in
{
  boot.loader.grub.enable = true;
  boot.loader.grub.configurationLimit = lib.mkDefault 5;

  environment.ldso32 = null;
  boot.tmp.cleanOnBoot = lib.mkDefault true;

  networking.firewall.enable = true;
  networking.firewall.logRefusedConnections = lib.mkDefault false;
  networking.useNetworkd = lib.mkDefault true;
  networking.hostName = host.name;

  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.network.wait-online.enable = false;
  systemd.services.systemd-networkd.stopIfChanged = false;
  systemd.services.systemd-resolved.stopIfChanged = false;

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

  # a full-disk scrub starves etcd fsyncs (etcd hang 2026-11-16): never scrub two nodes at once, keep it off midnight
  services.btrfs.autoScrub = {
    enable = true;
    interval = "${builtins.elemAt [ "Mon" "Wed" "Fri" ] (lib.mod (idx - 1) 3)} 03:00";
  };

  # IOSchedulingClass=idle has no effect on virtio disks, so cap scrub bandwidth instead (runtime sysfs value, set every boot)
  systemd.services.btrfs-scrub-limit = {
    description = "Limit btrfs scrub bandwidth";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.btrfs-progs}/bin/btrfs scrub limit --all --limit 50m /";
    };
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
