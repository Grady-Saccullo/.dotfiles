{inputs, ...}: final: prev: {
  unstable = import inputs.nixpkgs-unstable {
    system = final.system;
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
  };
  alejandra = inputs.alejandra.defaultPackage.${final.system};
  wezterm-nightly = inputs.wezterm;
}
