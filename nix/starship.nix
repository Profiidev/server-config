{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    starship
  ];

  programs.starship = {
    enable = true;

    settings = builtins.fromTOML ''
      ## FIRST LINE/ROW: Info & Status
      # First param \u2500\u250c
      [username]
      format = " [\u256d\u2500$user]($style)@"
      show_always = true
      style_root = "bold red"
      style_user = "bold red"

      # Second param
      [hostname]
      disabled = false
      format = "[$hostname]($style) in "
      ssh_only = false
      style = "bold dimmed red"
      trim_at = "-"

      # Third param
      [directory]
      style = "purple"
      truncate_to_repo = true
      truncation_length = 0
      truncation_symbol = "repo: "

      # Fourth param
      [sudo]
      #disabled = false
      disabled = true
      format = "[$symbol]($style)"

      # Before all the version info (python, nodejs, php, etc.)
      [git_status]
      ahead = "\u21e1''${count}"
      behind = "\u21e3''${count}"
      deleted = "x"
      diverged = "\u21d5\u21e1''${ahead_count}\u21e3''${behind_count}"
      style = "white"

      # Last param in the first line/row
      [cmd_duration]
      disabled = false
      format = "took [$duration]($style)"
      min_time = 1

      ## SECOND LINE/ROW: Prompt
      # Somethere at the beginning
      [battery]
      charging_symbol = "\uf583"
      disabled = true
      discharging_symbol = "\uf582"
      full_symbol = "\uf578"

      [[battery.display]] # "bold red" style when capacity is between 0% and 15%
      disabled = false
      style = "bold red"
      threshold = 15

      [[battery.display]] # "bold yellow" style when capacity is between 15% and 50%
      disabled = true
      style = "bold yellow"
      threshold = 50

      [[battery.display]] # "bold green" style when capacity is between 50% and 80%
      disabled = true
      style = "bold green"
      threshold = 80

      # Prompt: optional param 1
      [time]
      disabled = true
      format = " \U0001f559 $time($style)\n"
      style = "bright-white"
      time_format = "%T"

      # Prompt: param 2
      [character]
      error_symbol = " [�](bold red)"
      success_symbol = " [\u2570\u2500\u03bb](bold red)"

      # SYMBOLS
      [status]
      disabled = false
      format = '[\[$symbol$status_common_meaning$status_signal_name$status_maybe_int\]]($style)'
      map_symbol = true
      pipestatus = true
      symbol = "\U0001f534"

      [aws]
      symbol = "\ue33d "

      [conda]
      symbol = "\uf10c "

      [dart]
      symbol = "\ue798 "

      [docker_context]
      symbol = "\uf308 "

      [elixir]
      symbol = "\ue275 "

      [elm]
      symbol = "\ue62c "

      [git_branch]
      symbol = "\uf418 "

      [golang]
      symbol = "\ue627 "

      [hg_branch]
      symbol = "\uf418 "

      [java]
      symbol = "\ue256 "

      [julia]
      symbol = "\ue624 "

      [nim]
      symbol = "\uf6a4 "

      [nix_shell]
      symbol = "\uf2dc "

      [nodejs]
      symbol = "\ue24f "

      [package]
      symbol = "\uf8d6 "

      [perl]
      symbol = "\ue769 "

      [php]
      symbol = "\ue608 "

      [python]
      symbol = "\ue606 "

      [ruby]
      symbol = "\ue23e "

      [rust]
      symbol = "\ue7a8 "

      [swift]
      symbol = "\ufbe3 "
    '';
  };
}
