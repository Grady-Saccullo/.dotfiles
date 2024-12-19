{
  inputs,
  self,
  ...
}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: let
    mkApp = name: {
      type = "app";
      program = "${(pkgs.writeScriptBin name ''
        #!/usr/bin/env bash
        PATH=${inputs.alejandra.defaultPackage.${system}}./bin:$PATH
        echo "Running ${name} for ${system}"
        exec ${self}/apps/${name}
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
