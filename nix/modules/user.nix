{ ... }:

{
  users = {
    users.root = {
      initialHashedPassword = "$y$j9T$pnCZ4Brq.MWblahjyXaE3/$fX35Wosq8.3Ud5CQXfqtgok.HLZzyGByUcQRk2ZVTY7"; # Password: 1234
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBz5wvNTdRAnh/sHFKlanUuY0n6+fLeNkzjtNTRguBdI profidev@laptop"
      ];
    };

    mutableUsers = false;
  };
}
