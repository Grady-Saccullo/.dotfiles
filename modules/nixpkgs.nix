{inputs, ...}: {
  nixpkgs = {
    overlays = [(import ../overlays {inherit inputs;})];
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
  };
}
