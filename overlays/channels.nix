# pkgs.channels.<name>: an un-overlaid nixpkgs per source in mkDarwinHost's `channels`, for pinning
# one package while base pkgs stays unstable. Lazy: an unreferenced channel is never imported.
{channels}: final: _prev: {
  channels = builtins.mapAttrs (_: nixpkgs:
    import nixpkgs {
      localSystem = final.stdenv.hostPlatform.system;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
      };
      overlays = [];
    })
  channels;
}
