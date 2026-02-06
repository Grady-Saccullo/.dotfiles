{inputs, ...}: let
  stableOverlay = import ./stable.nix {inherit inputs;};
  unstableOverlay = import ./unstable.nix {inherit inputs;};
  yamlLanguageServerOverlay = import ./yaml-language-server.nix;
  weztermOverlay = import ./wezterm.nix {inherit inputs;};
  llmAgentsOverlay = inputs.llm-agents.overlays.default;
in
  final: prev:
    (stableOverlay final prev)
    // (unstableOverlay final prev)
    // (yamlLanguageServerOverlay final prev)
    // (weztermOverlay final prev)
    // (llmAgentsOverlay final prev)
