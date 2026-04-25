{
  utils,
  config,
  lib,
  pkgs,
  me,
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
      path = lib.mkOption {
        type = lib.types.str;
        default = "/Users/${me.user}/Applications/Home Manager Apps/WezTerm.app";
        description = "Path to the WezTerm application";
      };
    };
  } (cfg:
    utils.mkHomeManagerUser {
      programs.wezterm = {
        enable = true;
        package = cfg.package;
        extraConfig = builtins.readFile ./config.lua;
      };
    })
