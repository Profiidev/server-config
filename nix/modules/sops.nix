{ inputs, ... }:

{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = ../sops.yaml;
    validateSopsFiles = false;

    age = {
      sshKeyPaths = [
        "/etc/ssh/ssh_host_ed25519_key"
      ];
    };

    secrets."rke2_token" = {
      owner = "root";
      group = "wheel";
    };
  };
}
