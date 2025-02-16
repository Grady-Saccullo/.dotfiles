{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types;
  cfg = config.applications.neovim.typescript;
in {
  options = {
    applications.neovim.typescript = {
      enable = mkEnableOption "TypeScript";
      tsx.enable = mkEnableOption "TypeScript / TSX";
      lsp = mkOption {
        type = types.enum ["tsls" "vtsls"];
        default = "tsls";
        description = "TypeScript LSP server to use (tsls, vtsls)";
      };
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
  in
    lib.mkIf cfg.enable (utils.mkHomeManagerUser {
      programs.neovim.plugins =
        [
          (vimPlugins.nvim-treesitter.withPlugins (p: [p.typescript p.javascript]))
        ]
        ++ lib.optionals (cfg.lsp == "tsls") [
          vimPlugins.nvim-lsp-ts-utils
        ]
        ++ lib.optionals cfg.tsx.enable [
          (vimPlugins.nvim-treesitter.withPlugins (p: [p.tsx]))
        ];

      programs.neovim.extraPackages =
        lib.optionals (cfg.lsp == "tsls") [
          pkgs.unstable.typescript-language-server
        ]
        ++ lib.optionals (cfg.lsp == "vtsls") [
          pkgs.unstable.vtsls
        ];

      programs.neovim.extraLuaConfig =
        lib.optionalString (cfg.lsp == "tsls") ''
          ${builtins.readFile ./typescript-lsp-tsls.lua}
        ''
        + lib.optionalString (cfg.lsp == "vtsls") ''
          ${builtins.readFile ./typescript-lsp-vtsls.lua}
        '';
    });
}
