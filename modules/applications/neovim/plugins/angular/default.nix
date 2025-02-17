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
    "angular.enable"
  ];
in {
  options = {
    applications.neovim.angular = {
      enable = mkEnableOption "Angular";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.angular]))
      ];
    });
}
