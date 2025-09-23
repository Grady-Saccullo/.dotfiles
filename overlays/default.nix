{inputs, ...}: let
  unstableOverlay = import ./unstable.nix {inherit inputs;};
  yamlLanguageServerOverlay = import ./yaml-language-server.nix;
  luaLanguageServerOverlay = import ./lua-language-server.nix;
  weztermOverlay = import ./wezterm.nix {inherit inputs;};
in
  final: prev:
    (unstableOverlay final prev)
    // (yamlLanguageServerOverlay final prev)
    // (luaLanguageServerOverlay final prev)
    // (weztermOverlay final prev)
