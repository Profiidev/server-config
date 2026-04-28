{
  inputs,
  nix-config,
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

    ./modules/nix.nix
    ./modules/services.nix
    ./modules/user.nix

    "${nix-config}/modules/general.nix"
  ];
}
