{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = "bitwarden";
  extraOptions = {
    package = lib.mkPackageOption pkgs "bitwarden-desktop" {};
    browserExtension.enable = lib.mkEnableOption "Bitwarden Browser Extension";
    cli = {
      enable = lib.mkEnableOption "the Bitwarden CLI (`bw`)";
      package = lib.mkPackageOption pkgs "bitwarden-cli" {};
    };
  };
} (cfg:
    lib.mkMerge [
      (utils.mkPlatformConfig {
        darwin = {
          homebrew.masApps = {
            "Bitwarden" = 1352778147;
          };
        };
        nixos = utils.mkHomeManagerUser {
          home.packages = [cfg.package];
        };
        linux = utils.mkHomeManagerUser {
          home.packages = [cfg.package];
        };
      })
      (lib.mkIf cfg.cli.enable (utils.mkHomeManagerUser {
        home.packages = [cfg.cli.package];
      }))
      (lib.mkIf cfg.browserExtension.enable {
        browser.extensions.chromium.bitwarden = {
          id = "nngceckbapebfimnlniiiahkandclblb";
          description = "Bitwarden";
        };
      })
    ])
