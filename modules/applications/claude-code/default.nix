{
  config,
  lib,
  utils,
  pkgs,
  ...
}: let 
  cfg = config.applications.claude-code;
in {
  options = {
    applications.claude-code = {
      enable = lib.mkEnableOption "Claude Code";
    };
  };

  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    home.packages = [
      pkgs.unstable.claude-code
    ];
  });
}
