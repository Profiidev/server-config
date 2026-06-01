{
  inputs,
  ...
}:

{
  imports = [
    ../modules/hardware-configuration.nix
    ../modules/disko-config.nix
    {
      _module.args = {
        disk = "/dev/vda";
        withSwap = false;
        imageSize = "3G";
      };
    }
    inputs.disko.nixosModules.disko

    ../modules/cleanup.nix
    ../modules/docker.nix
    ../modules/forgejo.nix
    ../modules/host-name-change.nix
    ../modules/locale.nix
    ../modules/nix.nix
    ../modules/services.nix
    ../modules/user.nix
  ];

  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200n8"
  ];

  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
}
