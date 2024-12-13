{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption;
  inherit (inputs) self;
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
    lib.mkIf cfg.enable (self.utils.mkHomeManagerUser {
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
