{
  pkgs,
  config,
  ...
}: let
  configDir = "${config.home.homeDirectory}/.dotfiles/configs/nvim/.config/nvim";

  tresitterPlugins = (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
        p.bash
        p.dockerfile
        p.go
        p.html
        p.json
        p.lua
        p.nix
        p.python
        p.swift
        p.tsx
        p.typescript
  ]));

  treesitterParsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = tresitterPlugins.dependencies;
  };
in {
  home.file.".config/nvim".source = config.lib.file.mkOutOfStoreSymlink configDir;
  home.file.".dotfiles/configs/nvim/.config/nvim/lua/configs/nix.lua".text = ''
    vim.opt.runtimepath:append("${treesitterParsers}")
  '';

  home.file.".local/share/nvim/nix/nvim-treesitter/" = {
      source = tresitterPlugins;
      recursive = true;
  };

  programs.neovim = {
      enable = true;
      package = pkgs.unstable.neovim-unwrapped;

      defaultEditor = true;
      withNodeJs = true;
      vimAlias = true;

      plugins = [
        tresitterPlugins
      ];
  };
}
