{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption;
  inherit (inputs) self;
  cfg = config.applications.neovim.html;
in {
  options = {
    applications.neovim.html = {
      enable = mkEnableOption "HTML";
      htmx.enable = mkEnableOption "HTMX";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    lib.mkIf cfg.enable (self.utils.mkHomeManagerUser {
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.html p.css]))
      ];

      programs.neovim.extraPackages = lib.optionals cfg.htmx.enable [
        pkgs.unstable.htmx-lsp
      ];

      programs.neovim.extraLuaConfig = let
        templEnabled = config.applications.neovim.go.templ.enable;
      in ''
        addLspServer("html", {
              	filetypes = { "html", ${lib.optionals templEnabled "templ"}},
        })
        addLspServer("cssls", {})
        ${lib.optionals cfg.htmx.enable ''
          addLspServer("htmx", {
          	filetypes = { "html", ${lib.optionals templEnabled "templ"}},
          })
        ''}
      '';
    });
}
