{
  pkgs,
  config,
  ...
}: let
  home-packages = pkgs.callPackage ./packages.nix {};
  home-file = import ./file.nix {inherit config;};
in {
  imports = [
    ../shared/programs
  ];

  # TODO: look into home manager state version
  home.stateVersion = "24.05";

  home.packages = home-packages;

  home.file = home-file;

  home.sessionVariables = {
    EDITOR = "vim";
  };

  xdg.enable = true;
}
