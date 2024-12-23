{
  pkgs,
  utils,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.applications.wezterm;
in {
  options = {
    applications.wezterm = {
      enable = mkEnableOption "wezterm";
      package = mkOption {
        type = types.package;
        default = pkgs.wezterm-nightly.packages.${pkgs.system}.default;
      };
    };
  };
  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    programs = {
      wezterm = {
        enable = true;
        package = cfg.package;
        extraConfig = builtins.readFile ./config.lua;
        colorSchemes = {
          oxocarbon-dark = {
            background = "#161616";
            foreground = "#ffffff";
            cursor_bg = "#ffffff";
            cursor_border = "#ffffff";
            cursor_fg = "#161616";

            ansi = ["#262626" "#ee5396" "#42be65" "#ffe97b" "#33b1ff" "#ff7eb6" "#3ddbd9" "#dde1e6"];
            brights = ["#393939" "#ee5396" "#42be65" "#ffe97b" "#33b1ff" "#ff7eb6" "#3ddbd9" "#ffffff"];

            tab_bar = {
              background = "#262626";

              active_tab = {
                bg_color = "#161616";
                fg_color = "#ffffff";
                intensity = "Normal";
                italic = false;
                strikethrough = false;
                underline = "None";
              };

              inactive_tab = {
                bg_color = "#262626";
                fg_color = "#ffffff";
                intensity = "Normal";
                italic = false;
                strikethrough = false;
                underline = "None";
              };

              new_tab = {
                bg_color = "#262626";
                fg_color = "#ffffff";
                intensity = "Normal";
                italic = false;
                strikethrough = false;
                underline = "None";
              };
            };
          };
        };
      };
    };
  });
}
