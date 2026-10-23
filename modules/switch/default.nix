# Steps that `nix run .#switch` runs around the rebuild (./README.md). apps/switch reads `switch.plan`
# and realises everything it runs by building `switch.tools`.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.switch;
  enabledSteps = lib.filterAttrs (_: step: step.enable) cfg.steps;
  hook =
    if lib.any (step: step.secrets != {}) (lib.attrValues enabledSteps)
    then cfg.hook
    else null;

  # The switch joins these as `<step>.<label>` in its one request to the hook.
  validName = name: builtins.match "[A-Za-z0-9_-]+" name != null;

  checks =
    lib.mapAttrsToList (name: step: {
      assertion = step.secrets == {} || cfg.hook != null;
      message = ''
        ${lib.showOption ["switch" "steps" name "secrets"]} is set but there is no secrets hook to
        read it with. Set switch.hook, or secrets.hook (or a preset: secrets.backend) on this host;
        see modules/switch/README.md.
      '';
    })
    enabledSteps
    ++ lib.mapAttrsToList (name: step: let
      invalid = lib.filter (n: !validName n) ([name] ++ lib.attrNames step.secrets);
    in {
      assertion = invalid == [];
      message = ''
        ${lib.showOption ["switch" "steps" name]}: step names and secret labels may only use
        letters, digits, `_` and `-`, not: ${lib.concatStringsSep ", " invalid}.
      '';
    })
    cfg.steps;
  failed = lib.filter (check: !check.assertion) checks;

  removed = name:
    lib.mkRemovedOptionModule ["cachix" name] ''
      Cachix support left the framework. Log in to or push to a binary cache with switch steps
      instead: `switch.steps`, see modules/switch/README.md.
    '';
in {
  imports = [./options.nix] ++ map removed ["cache" "backend" "hook" "readToken" "pushToken"];

  config = {
    # `nix eval` of the plan skips `assertions`, so without this, preBuild steps would run on a host
    # whose build is about to fail on one.
    switch.plan = lib.throwIf (failed != []) (lib.concatMapStringsSep "\n" (check: check.message) failed) {
      version = 1;
      hook =
        if hook == null
        then null
        else lib.getExe hook;
      steps =
        lib.mapAttrsToList (name: step: {
          inherit name;
          inherit (step) phase secrets settings;
          exe = lib.getExe step.package;
        })
        enabledSteps;
    };

    switch.tools = pkgs.linkFarm "switch-tools" (
      lib.mapAttrsToList (name: step: {
        name = "steps/${name}";
        path = lib.getBin step.package;
      })
      enabledSteps
      ++ lib.optional (hook != null) {
        name = "hook";
        path = lib.getBin hook;
      }
    );

    assertions = checks;
  };
}
