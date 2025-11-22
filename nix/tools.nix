{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kubectl
    k9s
    helm
    btop
    fastfetch
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
}
