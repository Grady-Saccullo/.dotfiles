# Provides pkgs.stable for accessing stable nixpkgs packages
# (base pkgs is unstable for darwin compatibility)
{inputs, ...}: final: prev: {
  stable = import inputs.nixpkgs {
    localSystem = final.stdenv.hostPlatform.system;
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
    overlays = [];
  };
}
