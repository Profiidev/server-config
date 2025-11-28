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
        disk = "/dev/vda";
        withSwap = true;
        swapSize = "2";
      };
    }
    inputs.disko.nixosModules.disko

    ./docker.nix
    ./host-specific.nix
    ./nix.nix
    ./rke2.nix
    ./services.nix
    ./starship.nix
    ./tools.nix
    ./user.nix

    "${nix-config}/modules/general.nix"
    "${nix-config}/modules/locale.nix"
  ];
}
