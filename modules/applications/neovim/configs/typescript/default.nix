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
      pkgs.unstable.typescript-language-server
    ]
    ++ lib.optionals (cfg.lsp == "vtsls") [
      pkgs.unstable.vtsls
    ];

  extraLuaConfig =
    lib.optionalString (cfg.lsp == "tsls") ''
      ${builtins.readFile ./typescript-lsp-tsls.lua}
    ''
    + lib.optionalString (cfg.lsp == "vtsls") ''
      ${builtins.readFile ./typescript-lsp-vtsls.lua}
    '';
})
