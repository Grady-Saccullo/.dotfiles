{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (inputs) self;
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
      # NOTE: maybe add this in for work vs personal vs other...?
      # extensions.darkReader = mkEnableOption "Brave / Extension / Dark Reader";
      # extensions.youtubeDislike = mkEnableOption "Brave / Extension / YouTube Dislike";
    };
  };
  config = lib.mkIf cfg.enable (
    self.utils.mkHomeManagerUser {
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
    }
  );
}
