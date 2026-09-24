{inputs, ...}: let
  channelsOverlay = import ./channels.nix {inherit inputs;};
  weztermOverlay = import ./wezterm.nix {inherit inputs;};
  llmAgentsOverlay = inputs.llm-agents.overlays.shared-nixpkgs;
in
  final: prev:
    (channelsOverlay final prev)
    // (weztermOverlay final prev)
    // (llmAgentsOverlay final prev)
