{ config, ... }:

{
  # DRBD 9 from nixpkgs; the operator's drbd-module-loader cannot build modules on NixOS and is disabled
  boot.extraModulePackages = [ config.boot.kernelPackages.drbd ];
  boot.kernelModules = [
    "drbd"
    "drbd_transport_tcp"
    "dm_thin_pool"
    "dm_snapshot"
    "dm_writecache"
    "dm_cache"
    "dm_crypt"
  ];

  # thin_check/thin_repair for activating the linstor_vg/thin pool at boot
  services.lvm.boot.thin.enable = true;
}
