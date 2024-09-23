{pkgs, ...}: let
  vim-plugins = pkgs.unstable.vimPlugins;

  treesitter-plugins = vim-plugins.nvim-treesitter.withPlugins (p:
    with p; [
      angular
      bash
      comment
      css
      dockerfile
      gitignore
      go
      html
      java
      javascript
      jq
      json
      kotlin
      lua
      make
      nix
      ocaml
      python
      regex
      ruby
      rust
      sql
      swift
      templ
      toml
      tsx
      typescript
      yaml
      zig
    ]);
in {
  programs.neovim = {
    enable = true;
    package = pkgs.unstable.neovim-unwrapped;

    defaultEditor = true;
    withNodeJs = true;
    vimAlias = true;

    # lsp / tooling made available only to nvim
    extraPackages = with pkgs.unstable; [
      delve
      docker-compose-language-service
      gopls
      htmx-lsp
      kotlin-language-server
      lua-language-server
      nil
      nodePackages.bash-language-server
      nodePackages.typescript-language-server
      ocamlPackages.lsp
      pyright
      rubyPackages.ruby-lsp
      rust-analyzer
      sourcekit-lsp
      sqls
      stylua
      templ
      typescript
      typescript
      vscode-langservers-extracted
      yaml-language-server
      zls
    ];

    extraLuaConfig = ''
      ${builtins.readFile ./filetype.lua}
      ${builtins.readFile ./globals.lua}
      ${builtins.readFile ./highlight.lua}
      ${builtins.readFile ./keymap.lua}
      ${builtins.readFile ./opt.lua}
    '';

    plugins = [
      {
        plugin = vim-plugins.gitsigns-nvim;
        config = builtins.readFile configs/gitsigns.lua;
        type = "lua";
      }

      {
        plugin = treesitter-plugins;
        config = builtins.readFile configs/treesitter.lua;
        type = "lua";
      }

      {
        plugin = vim-plugins.nvim-cmp;
        config = builtins.readFile configs/cmp.lua;
        type = "lua";
      }

      {
        plugin = vim-plugins.nvim-lspconfig;
        config = builtins.readFile configs/lspconfig.lua;
        type = "lua";
      }

      {
        plugin = vim-plugins.oxocarbon-nvim;
        config = builtins.readFile configs/colorscheme.lua;
        type = "lua";
      }

      {
        plugin = vim-plugins.telescope-nvim;
        config = builtins.readFile configs/telescope.lua;
        type = "lua";
      }

      {
        plugin = vim-plugins.vim-slime;
        config = builtins.readFile configs/slime.lua;
        type = "lua";
      }

      vim-plugins.zig-vim
      vim-plugins.cmp-buffer
      vim-plugins.cmp-nvim-lsp
      vim-plugins.cmp-nvim-lua
      vim-plugins.cmp-path
      vim-plugins.cmp_luasnip
      vim-plugins.fidget-nvim
      vim-plugins.harpoon2
      vim-plugins.lspkind-nvim
      vim-plugins.luasnip
      vim-plugins.neoformat
      vim-plugins.nvim-lsp-ts-utils
      vim-plugins.nvim-treesitter-context
      vim-plugins.nvim-treesitter-textobjects
      vim-plugins.plenary-nvim
      vim-plugins.telescope-file-browser-nvim
      vim-plugins.telescope-fzf-native-nvim
      vim-plugins.vim-fugitive
      vim-plugins.vim-rhubarb
      vim-plugins.vim-vinegar
    ];
  };

  home.file."./.config/nvim/after/" = {
    source = ./after;
    recursive = true;
  };
}
