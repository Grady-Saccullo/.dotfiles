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
    "dap.go.enable"
  ];
in {
  options = {
    applications.neovim.dap.go = {
      enable = mkEnableOption "Dap / Go";
    };
  };

  config = mkIf enable (mkHomeManagerUser {
    programs.neovim.plugins = [
      {
        plugin = vimPlugins.nvim-dap-go;
        config = builtins.readFile ./dap-go.lua;
        type = "lua";
      }
    ];

    programs.neovim.extraPackages = [
      pkgs.unstable.delve
    ];
  });
}
