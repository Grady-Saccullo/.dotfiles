{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption;
  inherit (inputs) self;
  cfg = config.applications.neovim.angular;
in {
  options = {
    applications.neovim.angular = {
      enable = mkEnableOption "Angular";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    lib.mkIf cfg.enable (self.utils.mkHomeManagerUser {
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.angular]))
      ];
    });
}
