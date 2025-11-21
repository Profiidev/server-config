{
  inputs,
  nix-config,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
    {
      _module.args = {
        disk = "/dev/sda";
        withSwap = true;
        swapSize = "2";
      };
    }
    inputs.disko.nixosModules.disko

    ./nix.nix
    ./rke2.nix
    ./services.nix
    ./tools.nix
    ./user.nix

    "${nix-config}/modules/general.nix"
    "${nix-config}/modules/locale.nix"
  ];
}
