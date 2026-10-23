# Evaluated by tests/secrets.sh (`secrets`) and tests/switch.sh (`switch`): small hosts reduced to
# plain values, so the tests compare them and build nothing.
{flake}: let
  inherit (flake.inputs.nixpkgs-unstable) lib;
  host = modules:
    (flake.lib.mkDarwinHost {
      system = "aarch64-darwin";
      user = "test";
      inherit modules;
    })
    .config;
  drv = pkg:
    if pkg == null
    then null
    else pkg.drvPath;
  summary = config: {
    secretsHook = drv config.secrets.hook;
    switchHook = drv config.switch.hook;
    # A host with a failing switch assertion refuses to give a plan.
    plan = let
      result = builtins.tryEval (builtins.deepSeq config.switch.plan config.switch.plan);
    in
      if result.success
      then result.value
      else "refused";
    failing = map (a: a.message) (lib.filter (a: !a.assertion) config.assertions);
  };
  # What the host's own pkgs build for a preset, to compare the defaults against.
  utils = import "${flake}/modules/flake-parts/utils.nix" {
    inherit lib;
    me.user = "test";
    machineType = "darwin";
  };
  preset = config: readCommand:
    drv (utils.secrets.mkReadCommandHook {
      pkgs = config.nixpkgs.pkgs;
      inherit readCommand;
    });
  # steps <attrs of step name -> step without its package>: each step gets a package named after it.
  steps = defs: {pkgs, ...}: {
    switch.steps =
      lib.mapAttrs (name: def: {package = pkgs.writeShellScriptBin "${name}-step" "";} // def) defs;
  };
  hook = name: {pkgs, ...}: {secrets.hook = pkgs.writeShellScriptBin name "";};
  none = host [];
  op = host [{secrets.backend = "op";}];
in {
  secrets = {
    none = summary none;
    op = summary op // {expected = preset op ["op" "read" "--no-newline"];};
    custom = summary (host [(hook "my-hook")]);
    mcpWithoutHook = summary (host [
      {
        ai.mcpServers.x = {
          command = "/bin/x";
          env.T.secret = "t";
        };
      }
    ]);
  };

  switch = {
    none = summary none;
    op = summary op // {expected = preset op ["op" "read" "--no-newline"];};
    opWithSecrets = summary (host [
      {secrets.backend = "op";}
      (steps {
        login = {
          phase = "preBuild";
          secrets.token = "op://Vault/item/field";
        };
      })
    ]);
    custom = summary (host [
      (hook "my-hook")
      (steps {
        zz-push = {
          phase = "postSwitch";
          secrets.token = ["--field" "p"];
          settings = {
            cache = "my-cache";
            n = [1 2];
          };
        };
        aa-login = {
          phase = "preBuild";
          secrets.token = "r";
        };
        plain.phase = "postSwitch";
        off = {
          enable = false;
          phase = "preBuild";
          secrets.x = "x";
        };
      })
    ]);
    switchHookOnly = summary (host [
      ({pkgs, ...}: {switch.hook = pkgs.writeShellScriptBin "switch-only-hook" "";})
      (steps {
        login = {
          phase = "preBuild";
          secrets.token = "r";
        };
      })
    ]);
    switchHookOverrides = summary (host [
      {secrets.backend = "op";}
      ({pkgs, ...}: {switch.hook = pkgs.writeShellScriptBin "other-hook" "";})
      (steps {
        login = {
          phase = "preBuild";
          secrets.token = "r";
        };
      })
    ]);
    noStepSecrets = summary (host [(hook "my-hook") (steps {plain.phase = "postSwitch";})]);
    secretsWithoutHook = summary (host [
      (steps {
        needs = {
          phase = "preBuild";
          secrets.token = "t";
        };
      })
    ]);
    disabledWithoutHook = summary (host [
      (steps {
        off = {
          enable = false;
          phase = "preBuild";
          secrets.token = "t";
        };
      })
    ]);
    badNames = summary (host [
      (hook "my-hook")
      (steps {
        "a.b" = {
          phase = "preBuild";
          secrets."x.y" = "t";
        };
      })
    ]);
    removedCachix = summary (host [
      {
        cachix = {
          cache = "my-cache";
          backend = "op";
          hook = null;
          readToken = "r";
          pushToken = "p";
        };
      }
    ]);
  };
}
