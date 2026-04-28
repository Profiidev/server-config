{ pkgs, lib, ... }:

{
  users = {
    users.root = {
      initialHashedPassword = "$y$j9T$pnCZ4Brq.MWblahjyXaE3/$fX35Wosq8.3Ud5CQXfqtgok.HLZzyGByUcQRk2ZVTY7"; # Password: 1234
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBz5wvNTdRAnh/sHFKlanUuY0n6+fLeNkzjtNTRguBdI profidev@laptop"
      ];

      shell = lib.mkForce pkgs.fish;
    };

    mutableUsers = false;
  };

  programs.fish = {
    enable = true;
    generateCompletions = true;

    shellInit = ''
      set fish_greeting
      set -U fish_color_command blue
    '';

    interactiveShellInit = ''
      starship init fish | source
      fastfetch
    '';

    shellAliases = {
      nix-shell = "nix-shell --run fish";
      k = "kubectl";
      ls = "eza";
    };

    shellAbbrs = {
      l = "eza -l -a --icons --group-directories-first";
      rmf = "rm -rf";
      clr = "clear";
      k9s = "k9s -c ctx";
      n = "nvim";
    };
  };

  environment.systemPackages = with pkgs; [
    eza
  ];

  documentation.man.generateCaches = lib.mkForce false;
}
