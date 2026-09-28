# Built by tests/secrets.sh: env wrappers and a preset hook, to run with stub commands.
{flake}: let
  inherit (flake.inputs.nixpkgs-unstable) lib;
  pkgs = flake.inputs.nixpkgs-unstable.legacyPackages.${builtins.currentSystem};
  utils = import "${flake}/modules/flake-parts/utils.nix" {
    inherit lib;
    me.user = "test";
    machineType = "darwin";
  };
  fakeHook = pkgs.writeShellScriptBin "fake-secrets-hook" ''
    PATH=${pkgs.jq}/bin:$PATH
    exec /bin/bash -e ${./.}/fake-secrets-hook
  '';
  wrap = args: utils.secrets.mkEnvWrapper ({inherit pkgs; command = "/usr/bin/env";} // args);
in {
  wrapped = wrap {
    name = "test";
    hook = fakeHook;
    secretEnv = {
      A = "fake/read";
      B = "fake/odd";
    };
  };
  missing = wrap {
    name = "test";
    hook = fakeHook;
    secretEnv = {
      A = "fake/read";
      C = "fake/unknown";
    };
  };
  viaReadCommand = wrap {
    name = "rc";
    readCommand = ["fakecli" "get"];
    secretEnv.A = "fake/read";
  };
  opPreset = utils.secrets.mkReadCommandHook {
    inherit pkgs;
    readCommand = utils.secrets.readCommandFor.op;
  };
}
