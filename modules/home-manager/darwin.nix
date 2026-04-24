{
  pkgs,
  inputs,
  config,
  utils,
  ...
}: let
  inherit (inputs) self;
in
  {
    imports = [
      (inputs.home-manager.darwinModules.home-manager)
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    # When HM wants to manage a file that already exists unmanaged, rename
    # the existing file to <path>.backup instead of failing activation.
    # Safety net on first rebuild after adding new HM-managed paths (e.g.
    # ~/.claude/settings.json).
    home-manager.backupFileExtension = "backup";
  }
  // utils.mkHomeManagerUser {
    home.stateVersion = self.constants.stateVersion;

    xdg.enable = true;
  }
