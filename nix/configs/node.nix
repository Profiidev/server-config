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
        withSwap = true;
        swapSize = "2";
        imageSize = "2G";
      };
    }
    inputs.disko.nixosModules.disko

    ../modules/cleanup.nix
    ../modules/docker.nix
    ../modules/host-name-change.nix
    ../modules/locale.nix
    ../modules/nix.nix
    ../modules/rke2.nix
    ../modules/services.nix
    ../modules/sops.nix
    ../modules/shell.nix
    ../modules/tools.nix
    ../modules/user.nix
  ];

  boot.kernelModules = [
    "kvm-intel"
    "kvm-amd"
  ];
}
