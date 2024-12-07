extras: {
  pkgs,
  config,
  ...
}: let
  mkRepoSource = p: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${p}";
  shared-packages = pkgs.callPackage ../shared/home-manager/packages.nix {};
in {
  imports =
    extras.imports
    ++ [
      ../shared/home-manager/programs
    ];

  home.stateVersion = "24.11";

  home.packages = with pkgs.unstable;
    [
      brave
      discord
      docker
      gh
      spotify
    ]
    ++ shared-packages;

  home.file = {
    "personal".source = mkRepoSource "repos/personal";
    "krinkle".source = mkRepoSource "repos/krinkle";
  };

  xdg.enable = true;

  programs = {
    git = {
      userName = "Hackerman";
      userEmail = "gradys.dev@gmail.com";
    };
  };
}
