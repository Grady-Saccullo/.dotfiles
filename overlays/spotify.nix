final: prev: {
  spotify = prev.spotify.overrideAttrs (oldAttrs: {
    # this is annoying, but better than the package in nix which is using
    # web archives for pegged version
    src = prev.fetchurl {
      url = "https://download.scdn.co/SpotifyARM64.dmg";
      sha256 = "sha256-a3LPFX3/f58fuaEJmzcpsgI27yTaRltwftwOuJBN+nQ=";
      name = "SpotifyARM64.dmg";
    };
  });
}
