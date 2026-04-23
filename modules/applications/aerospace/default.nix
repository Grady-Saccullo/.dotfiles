{
  utils,
  config,
  lib,
  ...
}:
utils.mkAppModule {
  path = "aerospace";
  inherit config;
  extraOptions = {
    profile = lib.mkOption {
      type = lib.types.enum ["personal" "voze"];
      default = "personal";
      description = "Which aerospace profile to use (selects the shipped TOML). Names mirror host config names.";
    };
  };
} (cfg:
    utils.mkPlatformConfig {
      darwin = lib.mkMerge [
        {
          homebrew.casks = [
            {
              name = "aerospace";
              greedy = true;
            }
          ];
        }
        (utils.mkHomeManagerUser {
          xdg.configFile."aerospace/aerospace.toml".source =
            if cfg.profile == "personal"
            then ./personal.toml
            else ./voze.toml;
        })
      ];
      nixos = "aerospace is only supported on darwin";
      linux = "aerospace is only supported on darwin";
    })
