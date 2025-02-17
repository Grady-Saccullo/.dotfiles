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
    "rust.enable"
  ];
in {
  options = {
    applications.neovim.rust = {
      enable = mkEnableOption "Rust";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
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
