{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption;
  inherit (inputs) self;
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
    lib.mkIf cfg.enable (self.utils.mkHomeManagerUser {
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
