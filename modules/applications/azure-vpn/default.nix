{
  utils,
  config,
  ...
}:
utils.mkAppModule {
  path = "azure-vpn";
  inherit config;
} (cfg:
    utils.mkPlatformConfig {
      darwin = {
        homebrew.masApps = {
          "Azure VPN Client" = 1553936137;
        };
      };
      nixos = "Azure VPN is only supported on darwin";
      linux = "Azure VPN is only supported on darwin";
    })
