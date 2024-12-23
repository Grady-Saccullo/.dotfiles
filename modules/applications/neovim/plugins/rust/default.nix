{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.neovim.rust;
in {
  options = {
    applications.neovim.rust = {
      enable = mkEnableOption "Rust";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    lib.mkIf cfg.enable (utils.mkHomeManagerUser {
      programs.neovim.extraPackages = [
        pkgs.unstable.rust-analyzer
      ];
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.rust]))
      ];

      programs.neovim.extraLuaConfig = ''
        addLspServer("rust_analyzer", {
         	settings = {
         		diagnostics = {
         			enable = true,
         		},
         	},
         })
      '';
    });
}
