{ pkgs, ... }:

{
  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances.default = {
      enable = true;
      name = "test-runner";
      settings = {
        server = {
          connections = {
            forgejo = {
              url = "https://git.profidev.io/";
              uuid = "ed74dae9-f1d6-4e13-86a5-ef9c778d5ea0";
              token = "c0f82d7236cfb97244feb69667717d949725dc74";
            };
          };
        };
        runner = {
          name = "test-runner";
          labels = [
            "node-22:docker://node:22-bookworm"
            "nixos-latest:docker://nixos/nix"
            "ubuntu-latest:docker://node:16-bullseye"
            "ubuntu-22.04:docker://node:16-bullseye"
            "ubuntu-20.04:docker://node:16-bullseye"
            "ubuntu-18.04:docker://node:16-buster"
          ];
        };
      };
    };
  };

  networking.firewall.trustedInterfaces = [ "br-+" ];
}
