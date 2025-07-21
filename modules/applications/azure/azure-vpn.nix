{
  config,
  lib,
  utils,
  ...
}: let
  enable = utils.allEnable config.applications.azure [
    "enable"
    "vpn-client.enable"
  ];
in {
  options = {
    applications.azure.vpn-client = {
      enable = lib.mkEnableOption "Azure / VPN Client";
    };
  };

  config = lib.mkIf enable (utils.mkPlatformConfig {
    darwin = {
      homebrew.masApps = {
        "Azure VPN Client" = 1553936137;
      };
    };
    nixos = "Azure VPN is only supported on darwin";
    linux = "Azure VPN is only supported on darwin";
  });
}
