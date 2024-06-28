{pkgs, ...}: let
  isLinux = pkgs.stdenv.isLinux;
in
  with pkgs;
    [
      alejandra
      asciinema
      bat
      btop
      gh
      jq
      nodejs_22
      ripgrep
      tree
    ]
    ++ (lib.optionals isLinux [
      # additional packages
      git-credential-oauth

      # gui packages
      brave
      firefox
      spotify
    ])
