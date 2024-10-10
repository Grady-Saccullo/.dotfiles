{
  pkgs,
  config,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  mkRepoSource = p: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/${p}";
  shared-packages = pkgs.callPackage ../shared/home-manager/packages.nix {};
in {
  imports = [
    ../shared/home-manager/programs
  ];

  home.stateVersion = "24.11";

  home.packages = with pkgs;
    [
      asciinema
      gh
      unstable.zig
    ]
    ++ (lib.optionals isLinux [
      # gui packages
      brave
      firefox
      spotify
      wezterm
    ])
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
