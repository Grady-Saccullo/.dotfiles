{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  testEnabled = config.applications.neovim.test.enable;
in
  utils.mkNeovimModule {
    inherit config pkgs;
    imports = [./biome.nix ./tsx.nix];
    path = "typescript";
    extraOptions = {
      # typescript-language-server went with nvim-lsp-ts-utils, which nixpkgs removed.
      lsp = lib.mkOption {
        type = lib.types.enum ["vtsls"];
        default = "vtsls";
        description = "TypeScript LSP server to use";
      };
    };
    # tsx/jsx extensions only when tsx is on.
    extraConfig = cfg: {
      ai.lspServers.typescript = {
        command = "${pkgs.vtsls}/bin/vtsls";
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
    lazy,
    ...
  }: {
    plugins =
      [
        (vimPlugins.nvim-treesitter.withPlugins (p: [p.typescript p.javascript]))
      ]
      ++ lib.optionals testEnabled (lazy {
        plugin = vimPlugins.neotest-vitest.overrideAttrs (_: {
          dependencies = [];
          doCheck = false;
        });
        event = ["User HmNeotestAdapters"];
        config = ''
          addNeotestAdapter(function()
            return require("neotest-vitest")({})
          end)
        '';
      });

    extraPackages = [pkgs.vtsls];

    initLua = builtins.readFile ./typescript-lsp-vtsls.lua;
  })
