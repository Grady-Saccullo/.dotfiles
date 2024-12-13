{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkEnableOption;
  inherit (inputs) self;
  cfg = config.applications.neovim.typescript;
in {
  options = {
    applications.neovim.typescript = {
      enable = mkEnableOption "TypeScript";
      tsx.enable = mkEnableOption "TypeScript / TSX";
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    lib.mkIf cfg.enable (self.utils.mkHomeManagerUser {
      programs.neovim.plugins =
        [
          (vimPlugins.nvim-treesitter.withPlugins (p: [p.typescript p.javascript]))
          vimPlugins.nvim-lsp-ts-utils
        ]
        ++ lib.optionals cfg.tsx.enable [
          (vimPlugins.nvim-treesitter.withPlugins (p: [p.tsx]))
        ];
      programs.neovim.extraPackages = [
        pkgs.unstable.typescript-language-server
      ];

      programs.neovim.extraLuaConfig = ''
        ${builtins.readFile ./typescript-lsp.lua}
      '';
    });
}
