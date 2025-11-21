{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kubectl
    k9s
    helm
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
}
