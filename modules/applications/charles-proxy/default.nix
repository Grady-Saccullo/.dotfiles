{
  pkgs,
  utils,
  config,
  lib,
  ...
}: let
  cfg = config.applications.charles-proxy;
in {
  options = {
    applications.charles-proxy = {
      enable = lib.mkEnableOption "Charles Proxy";
    };
  };
  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    darwin = {
      homebrew.casks = [
        {
          name = "charles";
          greedy = true;
        }
      ];
    };
    nixos = utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.charles];
    };
    linux = utils.mkHomeManagerUser {
      home.packages = [pkgs.unstable.charles];
    };
  });
}
