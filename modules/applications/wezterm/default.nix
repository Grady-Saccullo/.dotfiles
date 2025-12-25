{
  utils,
  config,
  lib,
  pkgs,
  ...
}: let
  # it looks like during a recent update wezterm started relying on openssl,
  # or this has been a dependency but now is no longer on the system (not sure)
  # so as a work around adding in openssl to build inputs
  wezterm = pkgs.wezterm-nightly.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
    buildInputs =
      (oldAttrs.buildInputs or [])
      ++ [
        pkgs.unstable.openssl
        pkgs.pkg-config
      ];
  });
in
  utils.mkAppModule {
    path = "wezterm";
    inherit config;
    extraOptions = {
      package = lib.mkOption {
        type = lib.types.package;
        default = wezterm;
      };
    };
  } (cfg:
    utils.mkHomeManagerUser {
      programs.wezterm = {
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
              background = "rgba(0,0,0,0)";

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
    })
