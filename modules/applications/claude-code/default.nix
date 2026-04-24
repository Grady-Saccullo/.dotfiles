{
  utils,
  config,
  lib,
  pkgs,
  ...
}: let
  # Tool-agnostic Claude Code skills (i.e. not tied to a specific app) live
  # here. Each entry gets an `applications.claude-code.skills.<name>.enable`
  # option (default true) and is forwarded to home-manager's
  # `programs.claude-code.skills`, which symlinks it into ~/.claude/skills/.
  #
  # App-specific skills follow the same shape but are declared inside their
  # owning app module under `applications.<app>.ai.skills.<name>` — see
  # modules/applications/jj/default.nix for a worked example. Nothing in this
  # module needs to know about them; they contribute directly to
  # `programs.claude-code.skills` via the home-manager sink.
  ownedSkills = {
    # (none yet)
  };
in
  utils.mkAppModule {
    path = "claude-code";
    inherit config;
    extraOptions = {
      skills =
        lib.mapAttrs (name: meta: {
          enable =
            lib.mkEnableOption "the ${name} Claude Code skill (${meta.description})"
            // {default = true;};
        })
        ownedSkills;
    };
  } (cfg:
    utils.mkHomeManagerUser {
      programs.claude-code = {
        enable = true;
        package = pkgs.llm-agents.claude-code;
        # Mirrors the previously hand-maintained ~/.claude/settings.json so
        # rebuild doesn't clobber it. Override per-profile if needed.
        settings = {
          model = "opus[1m]";
          skipAutoPermissionPrompt = true;
          permissions.defaultMode = "auto";
        };
        skills =
          lib.mapAttrs (_: meta: meta.source)
          (lib.filterAttrs (name: _: cfg.skills.${name}.enable) ownedSkills);
      };
    })
