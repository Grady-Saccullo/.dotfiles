# Evaluated by tests/secrets.sh: small hosts reduced to what the secrets options produce, so the test
# compares plain values and builds nothing but the hooks.
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
    cachixHook = drv config.cachix.hook;
    inherit (config.cachix) switchConfig;
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
  op = host [{secrets.backend = "op";}];
  opRbw = host [{secrets.backend = "op"; cachix.backend = "rbw";}];
in {
  none = summary (host []);
  op = summary op // {expected = preset op ["op" "read" "--no-newline"];};
  opRbw = summary opRbw // {expected = preset opRbw ["rbw" "get"];};
  opNoCachixPreset = summary (host [{secrets.backend = "op"; cachix.backend = null;}]);
  custom = summary (host [
    ({pkgs, ...}: {
      secrets.hook = pkgs.writeShellScriptBin "my-hook" "";
      cachix = {
        cache = "my-cache";
        readToken = "r";
        pushToken = ["--field" "p"];
      };
    })
  ]);
  refsWithoutHook = summary (host [{cachix = {cache = "my-cache"; readToken = "r";};}]);
  refsWithoutCache = summary (host [{secrets.backend = "op"; cachix.readToken = "r";}]);
  mcpWithoutHook = summary (host [{ai.mcpServers.x = {command = "/bin/x"; env.T.secret = "t";};}]);
}
