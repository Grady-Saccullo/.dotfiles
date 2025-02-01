{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.neovim.python;
in {
  options = {
    applications.neovim.python = {
      enable = mkEnableOption "Python";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    lib.mkIf cfg.enable (utils.mkHomeManagerUser {
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
