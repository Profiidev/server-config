{
  inputs,
  ...
}:

{
  imports = [
    ./modules/hardware-configuration.nix
    ./modules/disko-config.nix
    {
      _module.args = {
        disk = "/dev/vda";
        withSwap = true;
        swapSize = "2";
      };
    }
    inputs.disko.nixosModules.disko

    ./modules/docker.nix
    ./modules/locale.nix
    ./modules/nix.nix
    ./modules/rke2.nix
    ./modules/services.nix
    ./modules/sops.nix
    ./modules/shell.nix
    ./modules/tools.nix
    ./modules/user.nix
  ];
}
