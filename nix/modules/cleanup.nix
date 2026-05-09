{ lib, ... }:

{
  documentation.enable = lib.mkDefault false;
  documentation.doc.enable = lib.mkDefault false;
  documentation.info.enable = lib.mkDefault false;
  documentation.man.enable = lib.mkDefault false;
  documentation.nixos.enable = lib.mkDefault false;

  fonts.fontconfig.enable = lib.mkDefault false;
  programs.command-not-found.enable = lib.mkDefault false;

  xdg.autostart.enable = lib.mkDefault false;
  xdg.icons.enable = lib.mkDefault false;
  xdg.menus.enable = lib.mkDefault false;
  xdg.mime.enable = lib.mkDefault false;
  xdg.sounds.enable = lib.mkDefault false;

  environment = {
    variables.BROWSER = "echo";
    stub-ld.enable = lib.mkDefault false;
  };
}
