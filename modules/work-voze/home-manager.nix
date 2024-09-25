{
  pkgs,
  config,
  ...
}: let
  shared-packages = pkgs.callPackage ../shared/home-manager/packages.nix {};
in {
  imports = [
    ../shared/home-manager/programs
  ];

  home.stateVersion = "24.11";

  home.packages = with pkgs;
    [
      gh
    ]
    ++ shared-packages;

  home.file = {
    "voze".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/repos/work/voze";
  };

  xdg.enable = true;

  programs = {
    git = {
      userName = "Grady Saccullo";
      userEmail = "gradys.dev@gmail.com";
    };
  };
}
