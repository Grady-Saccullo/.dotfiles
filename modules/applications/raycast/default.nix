{
  config,
  utils,
  lib,
  pkgs,
  ...
}: let
  cfg = config.applications.raycast;
in {
  options = {
    applications.raycast = {
      enable = lib.mkEnableOption "Raycast";
      browserExtension.enable = lib.mkEnableOption "Raycast Browser Extension";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (utils.mkPlatformConfig {
        darwin =
          utils.mkHomeManagerUser {
            home.packages = [pkgs.unstable.raycast];
          }
          // {
            launchd.user.agents.raycast = {
              command = "open ${pkgs.unstable.raycast}/Applications/Raycast.app";
              serviceConfig = {
                RunAtLoad = true;
              };
            };
          };
        nixos = "raycast is only supported on darwin";
        linux = "raycast is only supported on darwin";
      })

      (lib.mkIf cfg.browserExtension.enable {
        common.browserExtensions.chromium = [
          {id = "fgacdjnoljjfikkadhogeofgjoglooma";}
        ];
      })
    ]
  );
}
