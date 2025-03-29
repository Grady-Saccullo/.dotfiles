{
  utils,
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.applications.brave;
in {
  options = {
    applications.brave = {
      enable = mkEnableOption "Brave";
      package = mkOption {
        type = types.package;
        default = pkgs.unstable.brave;
      };
    };
  };
  config = lib.mkIf cfg.enable (utils.mkHomeManagerUser {
    programs.brave = {
      enable = true;
      package = cfg.package;
      extensions =
        [
          # Dark Reader
          {id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";}
          # YouTube Dislike
          {id = "gebbhagfogifgggkldgodflihgfeippi";}
        ]
        ++ config.common.browserExtensions.chromium;
    };
  });
}
