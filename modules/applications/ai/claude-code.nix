{
  config,
  lib,
  utils,
  pkgs,
  ...
}: let
  enable = utils.allEnable config.applications.ai [
    "enable"
    "claude-code.enable"
  ];
in {
  options = {
    applications.ai.claude-code = {
      enable = lib.mkEnableOption "ai / Claude Code";
    };
  };

  config = lib.mkIf enable (utils.mkHomeManagerUser {
    home.packages = [
      pkgs.unstable.claude-code
    ];
  });
}
