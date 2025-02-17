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
    "go.templ.enable"
  ];
in {
  options = {
    applications.neovim.go.templ = {
      enable = mkEnableOption "Go / templ";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.templ]))
      ];

      programs.neovim.extraPackages = [
        pkgs.unstable.templ
      ];

      programs.neovim.extraLuaConfig = ''
        ${builtins.readFile ./go-templ-lsp.lua}
      '';
    });
}
