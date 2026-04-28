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

    ./modules/docker.nix
    ./modules/nix.nix
    ./modules/rke2.nix
    ./modules/services.nix
    ./modules/sops.nix
    ./modules/starship.nix
    ./modules/tools.nix
    ./modules/user.nix

    "${nix-config}/modules/general.nix"
    "${nix-config}/modules/locale.nix"
  ];
}
