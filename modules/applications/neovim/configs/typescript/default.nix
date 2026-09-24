{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  imports = [./biome.nix ./tsx.nix];
  path = "typescript";
  extraOptions = {
    lsp = lib.mkOption {
      type = lib.types.enum ["tsls" "vtsls"];
      default = "tsls";
      description = "TypeScript LSP server to use (tsls, vtsls)";
    };
  };
  # Mirrors the `lsp` choice above; tsx/jsx extensions only when tsx is on.
  extraConfig = cfg: {
    ai.lspServers.typescript = {
      command =
        if cfg.lsp == "vtsls"
        then "${pkgs.vtsls}/bin/vtsls"
        else "${pkgs.typescript-language-server}/bin/typescript-language-server";
      args = ["--stdio"];
      extensionToLanguage =
        {
          ".ts" = "typescript";
          ".mts" = "typescript";
          ".cts" = "typescript";
          ".js" = "javascript";
          ".mjs" = "javascript";
          ".cjs" = "javascript";
        }
        // lib.optionalAttrs cfg.tsx.enable {
          ".tsx" = "typescriptreact";
          ".jsx" = "javascriptreact";
        };
      description = "typescript language server for AI tools";
    };
  };
} ({
  vimPlugins,
  cfg,
}: {
  plugins =
    [
      (vimPlugins.nvim-treesitter.withPlugins (p: [p.typescript p.javascript]))
    ]
    ++ lib.optionals (cfg.lsp == "tsls") [
      vimPlugins.nvim-lsp-ts-utils
    ];

  extraPackages =
    lib.optionals (cfg.lsp == "tsls") [
      pkgs.typescript-language-server
    ]
    ++ lib.optionals (cfg.lsp == "vtsls") [
      pkgs.vtsls
    ];

  initLua =
    lib.optionalString (cfg.lsp == "tsls") ''
      ${builtins.readFile ./typescript-lsp-tsls.lua}
    ''
    + lib.optionalString (cfg.lsp == "vtsls") ''
      ${builtins.readFile ./typescript-lsp-vtsls.lua}
    '';
})
