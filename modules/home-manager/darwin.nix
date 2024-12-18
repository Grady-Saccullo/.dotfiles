{
  pkgs,
  inputs,
  config,
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
  }
  // self.utils.mkHomeManagerUser {
    home.stateVersion = self.constants.stateVersion;

    xdg.enable = true;
  }
