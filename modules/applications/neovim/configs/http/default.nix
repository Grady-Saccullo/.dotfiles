{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  imports = [
    ./rest.nix
    # kulala-core went closed-source and license-gated at v7; 6.29 was the last version nixpkgs could ship.
    (lib.mkRemovedOptionModule ["applications" "neovim" "http" "kulala" "enable"] "kulala.nvim was removed; use applications.neovim.http.rest.enable.")
  ];
  path = "http";
} ({vimPlugins, ...}: {
  plugins = [
    (vimPlugins.nvim-treesitter.withPlugins (p: [p.http]))
  ];
})
