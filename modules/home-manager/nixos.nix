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
      (inputs.home-manager.nixosModules.home-manager)
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
  }
  // utils.mkHomeManagerUser {
    home.stateVersion = self.constants.stateVersion;
    xdg.enable = true;
  }
