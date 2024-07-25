{
  pkgs,
  config,
  ...
}: let
  configDir = "${config.home.homeDirectory}/.dotfiles/configs/nvim/.config/nvim";

  treesitterPlugins = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: with p; [
    angular
    bash
    css
    dockerfile
    go
    html
    json
    lua
    nix
    ocaml
    python
    rust
    swift
    tsx
    typescript
    zig
  ]);

  treesitterParsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = treesitterPlugins.dependencies;
  };
in {
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink configDir;

  home.file.".dotfiles/configs/nvim/.config/nvim/lua/configs/nix.lua".text = ''
    vim.g.treesitter_parsers_path = "${treesitterParsers}"
    vim.opt.runtimepath:append("${treesitterParsers}")
  '';

  home.file.".local/share/nvim/nix/nvim-treesitter" = {
    source = treesitterPlugins;
    recursive = true;
  };

  programs.neovim = {
    enable = true;
    package = pkgs.unstable.neovim-unwrapped;

    defaultEditor = true;
    withNodeJs = true;
    vimAlias = true;

    plugins = [
      treesitterPlugins
    ];

    extraPackages = with pkgs.unstable; [
      # lsp made available only to nvim
      docker-compose-language-service
      gopls
      htmx-lsp
      lua-language-server
      nil
      nodePackages.typescript-language-server
      ocamlPackages.lsp
      pyright
      rust-analyzer
      sourcekit-lsp
      sqls
      templ
      typescript
      vscode-langservers-extracted
      yaml-language-server
      zls
    ];
  };
}
