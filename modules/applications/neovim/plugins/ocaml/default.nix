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
    "ocaml.enable"
  ];
in {
  options = {
    applications.neovim.ocaml = {
      enable = mkEnableOption "OCaml";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.extraPackages = [
        pkgs.unstable.ocamlPackages.lsp
      ];
      programs.neovim.plugins = [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.ocaml]))
      ];

      programs.neovim.extraLuaConfig = ''
        addLspServer("ocamllsp", {})
      '';
    });
}
