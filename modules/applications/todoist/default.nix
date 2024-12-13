{
  config,
  inputs,
  lib,
  ...
}: let
  inherit (inputs) self;
  inherit (lib) mkEnableOption;
  cfg = config.applications.todoist;
in {
  options = {
    applications.todoist = {
      enable = mkEnableOption "Todoist";
    };
  };
  config = lib.mkIf cfg.enable (
    if self.utils.isNotMachine "darwin"
    then throw "todoist is only supported on darwin"
    else {
      homebrew.casks = [
        "todoist"
      ];
    }
  );
}
