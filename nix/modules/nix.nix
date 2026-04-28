{ pkgs, ... }:

{
  programs = {
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 1d --keep 10";
      clean.dates = "daily";
      flake = "/etc/nixos/nix-config";
    };
  };

  environment.systemPackages = with pkgs; [
    nil
    nixfmt-rfc-style
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "profidev"
    ];
  };

  nix.extraOptions = ''
    extra-substituters = https://cache.garnix.io https://nix-community.cachix.org
    extra-trusted-public-keys = cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
  '';

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };
}
