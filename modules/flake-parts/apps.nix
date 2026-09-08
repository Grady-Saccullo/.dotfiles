{self, ...}: {
  perSystem = {
    system,
    pkgs,
    lib,
    ...
  }: let
    mkApp = name: {
      type = "app";
      program = "${(pkgs.writeScriptBin name ''
        #!/usr/bin/env bash
        PATH=${lib.makeBinPath [pkgs.unstable.alejandra pkgs.unstable.jq pkgs.unstable.fzf pkgs.unstable.cachix pkgs.unstable.nixos-rebuild-ng pkgs.unstable.nixos-anywhere]}:$PATH
        echo "Running ${name} for ${system}"
        exec ${self}/apps/${name} "$@"
      '')}/bin/${name}";
    };
  in {
    apps = with builtins;
      listToAttrs (
        map (appName: {
          name = appName;
          value = mkApp appName;
        })
        (attrNames (readDir "${self}/apps"))
      );
  };
}
