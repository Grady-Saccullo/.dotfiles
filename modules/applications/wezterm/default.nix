{
  utils,
  config,
  lib,
  pkgs,
  me,
  ...
}:
utils.mkAppModule {
  path = "wezterm";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "wezterm" {};
    path = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${me.user}/Applications/Home Manager Apps/WezTerm.app";
      description = "Path to the WezTerm application";
    };
    bundleId = lib.mkOption {
      type = lib.types.str;
      default = "com.github.wez.wezterm";
      readOnly = true;
      description = "macOS bundle identifier, for window-manager rules and the like";
    };
    wezsesh.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the wezsesh plugin in the WezTerm config";
    };
    wezsesh.root = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${me.user}/code/grady-saccullo/wezsesh";
      description = "Checkout of the wezsesh repo; `plugin/` and the `wezsesh` binary are loaded from it";
    };
  };
} (cfg:
    utils.mkHomeManagerUser {
      programs.wezterm = {
        enable = true;
        package = cfg.package;
        enableZshIntegration = config.applications.zsh.enable;
        extraConfig =
          ''
            -- injected by nix: applications.wezterm.wezsesh.{enable,root}
            WEZSESH_ENABLED = ${lib.boolToString cfg.wezsesh.enable}
            WEZSESH_ROOT = "${cfg.wezsesh.root}"
          ''
          + builtins.readFile ./config.lua;
      };
    })
