{me, ...}: {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings = {
      trusted-users = ["root" "${me.user}"];
      netrc-file = "/etc/nix/netrc";
      # Public caches only. The personal grady-saccullo.cachix.org cache is
      # scoped to this flake's nixConfig (see flake.nix) instead of being a
      # machine-wide substituter, so it no longer leaks 401 warnings into
      # unrelated devenv projects.
      extra-substituters = [
        "https://cache.numtide.com"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}
