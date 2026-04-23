{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = "raycast";
  extraOptions = {
    browserExtension.enable = lib.mkEnableOption "Raycast Browser Extension";
  };
} (cfg:
    lib.mkMerge [
      (utils.mkPlatformConfig {
        darwin = {
          homebrew.casks = [
            {
              name = "raycast";
              greedy = true;
            }
          ];
        };
        nixos = "raycast is only supported on darwin";
        linux = "raycast is only supported on darwin";
      })
      (lib.mkIf cfg.browserExtension.enable {
        common.browserExtensions.chromium = [
          {id = "fgacdjnoljjfikkadhogeofgjoglooma";}
        ];
      })
    ])
