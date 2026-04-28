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
    let
      hosts = [
        {
          name = "node1";
          ip = "10.0.0.1";
          master = true;
        }
        {
          name = "node2";
          ip = "10.0.0.2";
          master = false;
        }
        {
          name = "node3";
          ip = "10.0.0.3";
          master = false;
        }
      ];
    in
    {
      nixosConfigurations =
        (builtins.listToAttrs (
          map (host: {
            name = host.name;
            value = nixpkgs-unstable.lib.nixosSystem {
              specialArgs = {
                lib = nixpkgs-unstable.lib;
                nix-config = (toString inputs.nix-config);
                inherit inputs host self;
              };
              modules = [
                ./config.nix
              ];
            };
          }) hosts
        ))
        // (builtins.listToAttrs (
          map (host: {
            name = "${host.name}-minimal";
            value = nixpkgs-unstable.lib.nixosSystem {
              specialArgs = {
                lib = nixpkgs-unstable.lib;
                nix-config = (toString inputs.nix-config);
                inherit inputs host self;
              };
              modules = [
                ./minimal.nix
              ];
            };
          }) hosts
        ));
    };
}
