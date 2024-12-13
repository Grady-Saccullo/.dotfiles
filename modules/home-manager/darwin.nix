{
  pkgs,
  inputs,
  config,
  ...
}: let
  inherit (inputs) self;
  # mkRepoSource = p: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${p}";
  # shared-packages = pkgs.callPackage ../shared/home-manager/packages.nix {};
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

    # home.file = {
    #   "personal".source = mkRepoSource "repos/personal";
    #   "krinkle".source = mkRepoSource "repos/krinkle";
    # };

    xdg.enable = true;
  }
