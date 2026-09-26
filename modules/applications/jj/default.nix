{
  utils,
  config,
  lib,
  pkgs,
  ...
}: let
  # ── AI contributions ────────────────────────────────────────────────────
  # This module contributes its Claude Code skill and hook to the
  # tool-agnostic `ai.*` bus (see modules/ai/README.md) instead of writing
  # to home-manager's `programs.claude-code.*` directly. The claude-code
  # application module is the sole consumer of the bus and materializes
  # these into ~/.claude/. Hosts opt out per entry:
  #
  #   ai.skills.jj-gh-pr.enable = false;
  #   ai.hooks.jj-pre-edit-warning.enable = false;
  #
  # Skill content lives at ./skills/<name>/SKILL.md. Adding another skill
  # is one `ai.skills.<name>` entry plus the SKILL.md file.
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
      package = lib.mkPackageOption pkgs "jujutsu" {};
    };
  } (cfg:
    (utils.mkHomeManagerUser {
      programs.jujutsu = {
        enable = true;
        package = cfg.package;
        settings = {
          user = {
            name = config.identity.name;
            email = config.identity.email;
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
    })
    // {
      shell.aliases.j = "jj";

      ai.skills.jj-gh-pr = {
        source = ./skills/jj-gh-pr;
        description = "opens GitHub PRs from jj bookmarks";
      };

      ai.hooks.jj-pre-edit-warning = {
        event = "PreToolUse";
        matcher = "Edit|Write|MultiEdit";
        script = preEditHookScript;
        description = "warns when editing while @ is at a pushed jj bookmark";
      };
    })
