{
  utils,
  config,
  lib,
  pkgs,
  ...
}:
utils.mkAppModule {
  inherit config;
  path = "_1password";
  extraOptions = {
    package = lib.mkPackageOption pkgs "_1password-gui" {};
    cli.package = lib.mkPackageOption pkgs "_1password-cli" {};
    browserExtension.enable = lib.mkEnableOption "1Password Browser Extension";
  };
} (cfg:
    lib.mkMerge [
      (utils.mkPlatformConfig {
        darwin = {
          homebrew.casks = [
            {
              name = "1password";
              greedy = true;
            }
          ];
          programs._1password = {
            enable = true;
            package = cfg.cli.package;
          };
        };
        linux = utils.mkHomeManagerUser {
          home.packages = [
            cfg.package
            cfg.cli.package
          ];
        };
        nixos = utils.mkHomeManagerUser {
          home.packages = [
            cfg.package
            cfg.cli.package
          ];
        };
      })
      (lib.mkIf cfg.browserExtension.enable {
        browser.extensions.chromium.onepassword = {
          id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
          description = "1Password";
        };
      })
    ])
