{pkgs, ...}: let
  vimPlugins = pkgs.unstable.vimPlugins;

  treesitter-plugins = vimPlugins.nvim-treesitter.withPlugins (p:
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

  vimPluginWithCfg = name: file:
      {
        plugin = vimPlugins.${name};
        config = builtins.readFile configs/${file}.lua;
        type = "lua";
      };
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
      # sourcekit-lsp
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
        plugin = treesitter-plugins;
        config = builtins.readFile configs/treesitter.lua;
        type = "lua";
      }

      (vimPluginWithCfg "gitsigns-nvim" "gitsigns")
      (vimPluginWithCfg "nvim-autopairs" "autopairs")
      (vimPluginWithCfg "nvim-cmp" "cmp")
      (vimPluginWithCfg "nvim-lspconfig" "lspconfig")
      (vimPluginWithCfg "oxocarbon-nvim" "colorscheme")
      (vimPluginWithCfg "telescope-nvim" "telescope")
      (vimPluginWithCfg "vim-slime" "slime")

      vimPlugins.cmp-buffer
      vimPlugins.cmp-nvim-lsp
      vimPlugins.cmp-nvim-lua
      vimPlugins.cmp-path
      vimPlugins.cmp_luasnip
      vimPlugins.fidget-nvim
      vimPlugins.harpoon2
      vimPlugins.lspkind-nvim
      vimPlugins.luasnip
      vimPlugins.neoformat
      vimPlugins.nvim-lsp-ts-utils
      vimPlugins.nvim-treesitter-context
      vimPlugins.nvim-treesitter-textobjects
      vimPlugins.plenary-nvim
      vimPlugins.telescope-file-browser-nvim
      vimPlugins.telescope-fzf-native-nvim
      vimPlugins.vim-fugitive
      vimPlugins.vim-rhubarb
      vimPlugins.vim-vinegar
      vimPlugins.zig-vim
    ];
  };

  home.file."./.config/nvim/after/" = {
    source = ./after;
    recursive = true;
  };
}
