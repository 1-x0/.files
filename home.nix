{ pkgs, const, cosmicLib, ... }:

{
  home.username = const.USERNAME;
  home.homeDirectory = "/home/${const.USERNAME}";
  home.stateVersion = const.STATE_VERSION;
  home.sessionVariables.NIXOS_OZONE_WL = "1";
  home.packages = [ pkgs.brave ];

  programs.git = {
    enable = true;
    settings.user = {
      name = const.USERNAME;
      email = const.EMAIL;
    };
  };

  home.persistence."/nix/persist/.home/${const.USERNAME}" = {
    directories = [
      "Documents"
      "Downloads"
      "Videos"
    ];
  };

  wayland.desktopManager.cosmic =
    let
      inherit (cosmicLib.cosmic) mkRON;
    in {
      enable = true;
      idle = {
        screen_off_time = mkRON "optional" null;
        suspend_on_ac_time = mkRON "optional" null;
        suspend_on_battery_time = mkRON "optional" null;
      };
      wallpapers = [
        {
          filter_by_theme = false;
          filter_method = mkRON "enum" "Lanczos";
          output = "all";
          rotation_frequency = 300;
          sampling_method = mkRON "enum" "Alphanumeric";
          scaling_mode = mkRON "enum" "Zoom";
          source = mkRON "enum" {
            value = [ "${./wallpaper.jpg}" ];
            variant = "Path";
          };
        }
      ];
    };
}
