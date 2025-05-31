{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (utils) allEnable mkHomeManagerUser;

  vimPlugins = pkgs.unstable.vimPlugins;
  enable = allEnable config.applications.neovim [
    "enable"
    "dap.enable"
  ];
in {
  imports = [./go.nix];
  options = {
    applications.neovim.dap = {
      enable = mkEnableOption "Dap";
    };
  };

  config = mkIf enable (mkHomeManagerUser {
    programs.neovim.plugins = [
      {
        plugin = vimPlugins.nvim-dap;
        config = builtins.readFile ./dap.lua;
        type = "lua";
      }
      {
        plugin = vimPlugins.nvim-dap-ui;
        config = builtins.readFile ./dap-ui.lua;
        type = "lua";
      }
      vimPlugins.nvim-nio
    ];
  });
}
