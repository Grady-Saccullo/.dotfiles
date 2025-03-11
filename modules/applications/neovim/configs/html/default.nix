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
    "html.enable"
  ];
in {
  imports = [./htmx.nix];
  options = {
    applications.neovim.html = {
      enable = mkEnableOption "HTML";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.html p.css]))
      ];

      programs.neovim.extraLuaConfig = let
        templEnabled = config.applications.neovim.go.templ.enable;
      in ''
        addLspServer("html", {
              	filetypes = { "html", ${lib.optionals templEnabled "templ"}},
        })
        addLspServer("cssls", {})
      '';
    });
}
