final: prev: {
  spotify = prev.spotify.overrideAttrs (oldAttrs: {
    src = prev.fetchurl {
      url = "https://download.scdn.co/SpotifyARM64.dmg";
      sha256 = "sha256-a3LPFX3/f58fuaEJmzcpsgI27yTaRltwftwOuJBN+nQ=";
      name = "SpotifyARM64.dmg";
    };
  });
}
