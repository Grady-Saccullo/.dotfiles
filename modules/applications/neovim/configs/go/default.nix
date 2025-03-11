{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (utils) mkHomeManagerUser allEnable;
  enable = allEnable config.applications.neovim [
    "enable"
    "go.enable"
  ];
in {
  imports = [./templ.nix];
  options = {
    applications.neovim.go = {
      enable = mkEnableOption "Go";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [
          p.go
          p.gomod
          p.gosum
          p.gowork
        ]))
      ];

      programs.neovim.extraPackages = [
        pkgs.unstable.gopls
      ];

      programs.neovim.extraLuaConfig = ''
        ${builtins.readFile ./go-lsp.lua}
      '';
    });
}
