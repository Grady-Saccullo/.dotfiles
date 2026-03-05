{me, ...}: {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings = {
      trusted-users = ["root" "${me.user}"];
      extra-substituters = [
        "https://cache.numtide.com"
        "https://grady-saccullo.cachix.org"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "grady-saccullo.cachix.org-1:eYGgNiaxvbtKg9XDaDw8POg+R92uwljqdlcE32nL9ts="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}
