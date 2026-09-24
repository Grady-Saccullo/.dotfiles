# Framework-owned hooks: shared lifecycle hooks that are not tied to one app
# module. Scripts live in ./hooks/ with @jq@ / @python3@ placeholders that
# `pkgs.replaceVars` swaps for store paths, so a hook never depends on what
# the launching shell happens to have on PATH.
#
# Hosts opt out per hook with `ai.hooks.<name>.enable = false;`.
{pkgs, ...}: let
  jq = "${pkgs.jq}/bin/jq";
  python3 = "${pkgs.python3.withPackages (ps: [ps.pyyaml])}/bin/python3";
in {
  ai.hooks.validate-yaml = {
    event = "PostToolUse";
    matcher = "Edit|Write";
    script = pkgs.replaceVars ./hooks/validate-yaml.sh {inherit jq python3;};
    description = "fail loudly when an edited .yml/.yaml no longer parses";
  };

  ai.hooks.protect-ci-workflows = {
    event = "PreToolUse";
    matcher = "Edit|Write";
    script = pkgs.replaceVars ./hooks/protect-ci-workflows.sh {inherit jq;};
    description = "confirm before editing .github/workflows/* or action.yml";
  };
}
