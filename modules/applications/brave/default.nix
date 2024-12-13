{
  inputs,
  lib,
  config,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.brave;
in {
  options = {
    applications.brave = {
      enable = mkEnableOption "Brave";
      # NOTE: maybe add this in for work vs personal vs other...?
      # extensions.darkReader = mkEnableOption "Brave / Extension / Dark Reader";
      # extensions.youtubeDislike = mkEnableOption "Brave / Extension / YouTube Dislike";
    };
  };
  config = lib.mkIf cfg.enable (
    self.utils.mkHomeManagerUser {
      programs.brave = {
        enable = true;
        extensions = [
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
