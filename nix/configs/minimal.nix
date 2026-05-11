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
      };
    }
    inputs.disko.nixosModules.disko

    ../modules/cleanup.nix
    ../modules/locale.nix
    ../modules/nix.nix
    ../modules/services.nix
    ../modules/user.nix
  ];
}
