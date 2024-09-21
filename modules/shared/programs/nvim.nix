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
    java
    javascript
    json
    kotlin
    lua
    nix
    ocaml
    python
    regex
    ruby
    rust
    swift
    sql
    tsx
    typescript
    templ
    yaml
    zig
  ]);

  treesitterParsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = treesitterPlugins.dependencies;
  };

  # ruby-lsp-wrapper = pkgs.writeShellScriptBin "ruby-lsp-wrapper" ''
  #   export GEM_HOME="$HOME/.local/share/nvim/ruby-lsp/gems"
  #   export GEM_PATH="$GEM_HOME:$GEM_PATH"
  #   export PATH="$GEM_HOME/bin:$PATH"
  #
  #   # Ensure the GEM_HOME directory exists
  #   mkdir -p "$GEM_HOME"
  #
  #   # Run ruby-lsp
  #   exec ${pkgs.rubyPackages.ruby-lsp}/bin/ruby-lsp "$@"
  # '';
in {
  # home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink configDir;
  home.file."./.config/nvim" = {
    source = config.lib.file.mkOutOfStoreSymlink configDir;
    # source = ../../../configs/nvim/.config/nvim;
    # recursive = true;
  };

  # vim.g.treesitter_parsers_path = "${treesitterParsers}"
  home.file."./.dotfiles/configs/nvim/.config/nvim/lua/configs/nix.lua".text = ''
    vim.opt.runtimepath:append("${treesitterParsers}")
  '';


  home.file."./.local/share/nvim/nix/nvim-treesitter/" = {
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
      delve
      docker-compose-language-service
      gopls
      htmx-lsp
      kotlin-language-server
      lua-language-server
      nil
      nodePackages.bash-language-server
      nodePackages.typescript-language-server
      typescript
      ocamlPackages.lsp
      pyright
      rubyPackages.ruby-lsp
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
