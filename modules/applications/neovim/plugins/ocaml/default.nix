{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption;
  cfg = config.applications.neovim.ocaml;
in {
  options = {
    applications.neovim.ocaml = {
      enable = mkEnableOption "OCaml";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    lib.mkIf cfg.enable (utils.mkHomeManagerUser {
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
