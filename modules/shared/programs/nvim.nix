{
  pkgs,
  config,
  ...
}: let
  configDir = "${config.home.homeDirectory}/.dotfiles/configs/nvim/.config/nvim";

  treesitterPlugins = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
    p.bash
    p.dockerfile
    p.go
    p.css
    p.html
    p.json
    p.lua
    p.nix
    p.ocaml
    p.python
    p.rust
    p.swift
    p.tsx
    p.typescript
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
      gopls
      htmx-lsp
      lua-language-server
      nil
      ocamlPackages.lsp
      pyright
      rust-analyzer
      sourcekit-lsp
      sqls
      templ
      vscode-langservers-extracted
      zls
    ];
  };
}
