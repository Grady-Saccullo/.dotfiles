{
  utils,
  config,
  lib,
  pkgs,
  ...
}: let
  # Claude Code skills owned by this module. Each entry:
  #   - gets an `applications.jj.ai.skills.<name>.enable` option (default true)
  #   - is forwarded to `programs.claude-code.skills.<name>` when enabled,
  #     which home-manager symlinks into ~/.claude/skills/<name>/.
  # Skill content lives at ./skills/<name>/SKILL.md. Adding a new skill is a
  # single new entry here plus the SKILL.md file; options and contributions
  # are derived automatically.
  ownedSkills = {
    jj-gh-pr = {
      source = ./skills/jj-gh-pr;
      description = "opens GitHub PRs from jj bookmarks";
    };
  };

  # Claude Code PreToolUse hook: warn the user when `@` sits at a bookmark
  # that's also tracked at origin. Prevents accidentally auto-amending a
  # published commit (jj snapshots the working copy into `@` on every
  # command, so edits with no `jj new` first end up in whatever commit `@`
  # currently is — which is how pushed feature branches get polluted).
  # Silent on non-jj repos and on unpushed bookmarks.
  preEditHookScript = ''
    #!/usr/bin/env bash
    [ -d .jj ] || exit 0
    command -v jj >/dev/null 2>&1 || exit 0

    names=$(jj log -r @ -T 'bookmarks.join(" ")' --no-graph 2>/dev/null \
      | tr ' ' '\n' | grep -v '@' | tr -d '*?' || true)

    for bm in $names; do
      [ -n "$bm" ] || continue
      if jj bookmark list "$bm" 2>/dev/null | grep -qE "^  @origin( |:|\()"; then
        echo "jj: @ is at pushed bookmark '$bm'. Consider 'jj new' before editing to avoid amending it." >&2
        exit 0
      fi
    done

    exit 0
  '';
in
  utils.mkAppModule {
    path = "jj";
    inherit config;
    default = true;
    extraOptions = {
      ai.skills =
        lib.mapAttrs (name: meta: {
          enable =
            lib.mkEnableOption "the ${name} Claude Code skill (${meta.description})"
            // {default = true;};
        })
        ownedSkills;
      ai.hooks.pre-edit-warning.enable =
        lib.mkEnableOption "PreToolUse hook that warns when editing while @ is at a pushed jj bookmark"
        // {default = true;};
    };
  } (cfg:
    utils.mkHomeManagerUser {
      programs.jujutsu = {
        enable = true;
        package = pkgs.unstable.jujutsu;
        settings = {
          user = {
            name = config.applications.git.username;
            email = config.applications.git.email;
          };
          ui = {
            default-command = "log";
            diff-formatter = ":git";
            pager = "delta";
            diff-editor = ":builtin";
            merge-editor = ":builtin";
          };
          git = {
            push-bookmark-prefix = "gs/";
          };
        };
      };

      programs.zsh = lib.mkIf config.applications.zsh.enable {
        shellAliases = {
          j = "jj";
        };
      };

      programs.claude-code.skills =
        lib.mapAttrs (_: meta: meta.source)
        (lib.filterAttrs (name: _: cfg.ai.skills.${name}.enable) ownedSkills);

      programs.claude-code.hooks =
        lib.mkIf cfg.ai.hooks.pre-edit-warning.enable {
          pre-edit-jj-warn = preEditHookScript;
        };

      programs.claude-code.settings.hooks.PreToolUse =
        lib.optionals cfg.ai.hooks.pre-edit-warning.enable [
          {
            matcher = "Edit|Write|MultiEdit";
            hooks = [
              {
                type = "command";
                command = ''bash "$HOME/.claude/hooks/pre-edit-jj-warn"'';
              }
            ];
          }
        ];
    })
