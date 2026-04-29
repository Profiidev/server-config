{
  lib,
  modulesPath,
  host,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  services.qemuGuest.enable = true;

  networking.interfaces.ens7 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = host.ip;
        prefixLength = 24;
      }
    ];
  };
}
