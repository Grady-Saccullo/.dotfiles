{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkEnableOption mkOption mkIf types;
  inherit (utils) allEnable mkHomeManagerUser;

  enable = allEnable config.applications.neovim [
    "enable"
    "typescript.enable"
  ];
in {
  imports = [./tsx.nix];
  options = {
    applications.neovim.typescript = {
      enable = mkEnableOption "TypeScript";
      lsp = mkOption {
        type = types.enum ["tsls" "vtsls"];
        default = "tsls";
        description = "TypeScript LSP server to use (tsls, vtsls)";
      };
    };
  };

  config = let
    vimPlugins = pkgs.unstable.vimPlugins;
    lsp = config.applications.neovim.typescript.lsp;
  in
    mkIf enable (mkHomeManagerUser {
      programs.neovim.plugins =
        [
          (vimPlugins.nvim-treesitter.withPlugins (p: [p.typescript p.javascript]))
        ]
        ++ lib.optionals (lsp == "tsls") [
          vimPlugins.nvim-lsp-ts-utils
        ];

      programs.neovim.extraPackages =
        lib.optionals (lsp == "tsls") [
          pkgs.unstable.typescript-language-server
        ]
        ++ lib.optionals (lsp == "vtsls") [
          pkgs.unstable.vtsls
        ];

      programs.neovim.extraLuaConfig =
        lib.optionalString (lsp == "tsls") ''
          ${builtins.readFile ./typescript-lsp-tsls.lua}
        ''
        + lib.optionalString (lsp == "vtsls") ''
          ${builtins.readFile ./typescript-lsp-vtsls.lua}
        '';
    });
}
