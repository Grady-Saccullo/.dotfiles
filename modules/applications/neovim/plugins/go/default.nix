{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.applications.neovim.go;
  inherit (lib) mkEnableOption;
  inherit (inputs) self;
in {
  options = {
    applications.neovim.go = {
      enable = mkEnableOption "Go";
      templ.enable = mkEnableOption "Go / templ";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    lib.mkIf cfg.enable (self.utils.mkHomeManagerUser {
      programs.neovim.plugins =
        [
          (vimPlugins.nvim-treesitter.withPlugins (p: [
            p.go
            p.gomod
            p.gosum
            p.gowork
          ]))
        ]
        ++ lib.optionals cfg.templ.enable [
          (vimPlugins.nvim-treesitter.withPlugins (p: [p.templ]))
        ];

      programs.neovim.extraPackages =
        [
          pkgs.unstable.gopls
        ]
        ++ lib.optionals cfg.templ.enable [
          pkgs.unstable.templ
        ];

      programs.neovim.extraLuaConfig = ''
        ${builtins.readFile ./go-lsp.lua}
        ${lib.optionals cfg.templ.enable (builtins.readFile ./go-templ-lsp.lua)}
      '';
    });
}
