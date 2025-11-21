{ ... }:

{
  users = {
    users.profidev = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];

      initialHashedPassword = "$y$j9T$egeObugZWCSrOzz6o8FUQ.$Xdxwp/BhUwGmgz.yfzKtJrRBe2.KtrGAVjVsmDEx6y2"; # Password.123
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBz5wvNTdRAnh/sHFKlanUuY0n6+fLeNkzjtNTRguBdI profidev@laptop"
      ];
    };

    mutableUsers = false;
  };
}
