{
  description = "Cluster node config";
  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-config = {
      url = "github:ProfiiDev/nix/main";
      flake = false;
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    inputs@{ self, nixpkgs-unstable, ... }:
    {
      nixosConfigurations = builtins.listToAttrs (
        map
          (host: {
            name = host;
            value = nixpkgs-unstable.lib.nixosSystem {
              specialArgs = {
                lib = nixpkgs-unstable.lib;
                nix-config = (builtins.toString inputs.nix-config);
                inherit host inputs self;
              };
              modules = [
                ./config.nix
              ];
            };
          })
          [
            "node1"
            "node2"
            "node3"
          ]
      );
    };
}
