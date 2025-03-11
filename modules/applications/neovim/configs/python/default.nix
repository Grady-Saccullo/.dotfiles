{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (utils) allEnable mkHomeManagerUser;
  enable = allEnable config.applications.neovim [
    "enable"
    "python.enable"
  ];
in {
  options = {
    applications.neovim.python = {
      enable = mkEnableOption "Python";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.python]))
      ];
      programs.neovim.extraPackages = [
        pkgs.unstable.basedpyright
      ];
      programs.neovim.extraLuaConfig = ''
        addLspServer("basedpyright", {})
      '';
    });
}
