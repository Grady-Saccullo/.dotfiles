# pkgs.channels.v<major>_<minor>: a full, un-overlaid nixpkgs for every flake input
# named nixpkgs-<major>_<minor>. Use it to pin ONE package to a release
# (pkgs.channels.v26_05.foo) while base pkgs stays nixpkgs-unstable.
# Sets are lazy: a channel is only imported when something references it.
{inputs, ...}: final: prev: let
  lib = prev.lib;
  releaseInputs =
    lib.filterAttrs
    (n: _: lib.hasPrefix "nixpkgs-" n && n != "nixpkgs-unstable")
    inputs;
  # nixpkgs-26_05 -> v26_05: a bare identifier (attribute names cannot start with a digit).
  releaseName = n: "v" + lib.removePrefix "nixpkgs-" n;
  mkChannel = input:
    import input {
      localSystem = final.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
      };
      overlays = [];
    };
in {
  channels =
    lib.mapAttrs'
    (n: input: lib.nameValuePair (releaseName n) (mkChannel input))
    releaseInputs;
}
