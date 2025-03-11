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
    "html.htmx.enable"
  ];
in {
  options = {
    applications.neovim.html.htmx = {
      enable = mkEnableOption "HTML / HTMX";
    };
  };

  config = mkIf enable (mkHomeManagerUser {
    programs.neovim.extraPackages = [
      pkgs.unstable.htmx-lsp
    ];

    programs.neovim.extraLuaConfig = let
      templEnabled = config.applications.neovim.go.templ.enable;
    in ''
      addLspServer("htmx", {
      	filetypes = { "html", ${lib.optionals templEnabled "templ"}},
      })
    '';
  });
}
