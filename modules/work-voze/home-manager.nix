{
  pkgs,
  config,
  ...
}: let
  shared-packages = pkgs.callPackage ../shared/home-manager/packages.nix {};
  mkRepoSource = p: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${p}";
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
    "voze".source = mkRepoSource "repos/work/voze";
  };

  xdg.enable = true;

  programs = {
    git = {
      userName = "Grady Saccullo";
      userEmail = "gradys.dev@gmail.com";
    };
  };
}
