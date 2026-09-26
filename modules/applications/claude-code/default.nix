{
  utils,
  config,
  lib,
  pkgs,
  ...
}: let
  # ── Role of this module ────────────────────────────────────────────────
  # This module is the ONLY writer of home-manager's `programs.claude-code.*`.
  # It consumes the tool-agnostic `ai.*` bus (declared in modules/ai/) and
  # fans it out to Claude Code:
  #
  #   ai.skills / ai.agents / ai.commands / ai.rules  → ~/.claude/<kind>/…
  #   ai.hooks     → ~/.claude/hooks/<name> + a `hooks.<event>` entry in the
  #                  enforced managed-settings.json
  #   ai.permissions → `permissions.allow/ask/deny` in the same managed file,
  #                  unioned with the host's managedSettings.permissions
  #   ai.plugins   → personal plugins under ~/.claude/skills/<name>/
  #   ai.context   → ~/.claude/CLAUDE.md (only when non-empty)
  #   ai.lspServers → `.lsp.json` in the personal plugin HM synthesises
  #                  (programs.claude-code.lspServers)
  #   ai.mcpServers → NOT handled here. modules/ai/mcp.nix populates the
  #                  shared `programs.mcp.servers` registry; this module just
  #                  opts in with `enableMcpIntegration`.
  #
  # App modules (jj, …) and host configs all contribute to `ai.*`; none of
  # them touch `programs.claude-code.*` directly. That keeps the dependency
  # graph one-directional: bus → this consumer → HM.
  #
  # ── Why this module splits settings across two files ────────────────────
  # home-manager renders `programs.claude-code.settings` to a /nix/store path
  # and symlinks ~/.claude/settings.json at it (read-only). But Claude Code
  # rewrites that file at runtime (changing model via /model, effort, theme,
  # …) with an atomic tmp+rename, which fails with EACCES against the
  # read-only store target. Upstream declined to fix it (claude-code#55485
  # "not planned"), HM has no mutable-file option, and mkOutOfStoreSymlink is
  # broken by claude-code#15786 (only one symlink level is resolved).
  #
  # Instead of merging policy into the user file on every switch, we use the
  # settings-precedence layer Claude Code ships for exactly this:
  #
  #   managed-settings.json  — highest precedence, read-only BY DESIGN (the
  #                            app never writes it). Nix owns it outright,
  #                            per platform:
  #                              darwin — /Library/Application Support/
  #                                       ClaudeCode/, root activation script
  #                              nixos  — /etc/claude-code/ via
  #                                       environment.etc (a read-only store
  #                                       symlink is fine here since the app
  #                                       never writes the file)
  #                              linux  — no root to write /etc/claude-code,
  #                                       so the same policy is merged into
  #                                       the user's settings.json on every
  #                                       switch instead (caveat: a key
  #                                       removed from nix lingers there
  #                                       until deleted by hand)
  #                            All enforced policy lives here: the
  #                            `applications.claude-code.managedSettings`
  #                            option plus the hook wiring derived from
  #                            `ai.hooks`. It is computed ONCE, at darwin
  #                            level, in this file — there is no readback of
  #                            home-manager state. Hooks and permissions
  #                            merge across scopes at runtime, so user-added
  #                            /hooks in settings.json coexist with these.
  #                            Removing a key here removes the policy — no
  #                            stale keys linger in the user file.
  #
  #   ~/.claude/settings.json — a real writable file owned by Claude Code.
  #                            We only SEED it (`seedSettings`, default
  #                            model) when it is absent, a stale store
  #                            symlink, or corrupt; runtime state (model via
  #                            /model, effort, theme, …) is otherwise never
  #                            touched.
  #
  # `model` intentionally stays OUT of managedSettings: there it would pin
  # the startup model on every launch, whereas as a seed the /model choice
  # persists across sessions and rebuilds.
  #
  # `programs.claude-code.settings` is deliberately left EMPTY so HM never
  # renders its own settings.json (it only does so when settings or
  # marketplaces are non-empty).
  #
  # Paths: this module assumes the upstream default config dir
  # `$HOME/.claude`. Repointing `programs.claude-code.configDir` is not
  # supported by design — the hook commands in managed-settings.json are
  # rendered at darwin level where the HM option is not in scope.
  #
  # Note: managed-settings.json is machine-wide (all users). On darwin it is
  # not removed if this module is disabled — delete it by hand in that case
  # (NixOS's environment.etc cleans up after itself).
  schemaUrl = "https://json.schemastore.org/claude-code-settings.json";
  darwinManagedDir = "/Library/Application Support/ClaudeCode";
  jsonFormat = pkgs.formats.json {};

  # The tool-agnostic bus, bound from the OUTER darwin `config` so the HM
  # inner function below (which rebinds `config` to the HM config) can still
  # reach it.
  ai = config.ai;
in
  utils.mkAppModule {
    path = "claude-code";
    inherit config;
    extraOptions = {
      package = lib.mkPackageOption pkgs "claude-code" {};

      managedSettings = lib.mkOption {
        inherit (jsonFormat) type;
        default = {};
        description = ''
          Enforced policy rendered into the root-owned managed-settings.json
          (highest precedence, never written by the app). Hooks from
          `ai.hooks` are merged in automatically.
        '';
      };

      seedSettings = lib.mkOption {
        inherit (jsonFormat) type;
        default = {};
        description = ''
          Mutable defaults written to ~/.claude/settings.json only when no
          valid file exists; runtime changes (/model etc.) persist.
        '';
      };
    };
  } (cfg: let
    # ── Content, derived from the bus ───────────────────────────────────
    # Entries with neither `source` nor `text` are dropped HERE rather than
    # in `utils.enabled`: modules/ai/default.nix relies on `enabled` to
    # still see them so its "exactly one of source/text" assertion fires.
    # If the resulting `null` reached home-manager, its option type check
    # would abort evaluation before that assertion is ever reported.
    contentOf = entries:
      lib.mapAttrs (_: utils.content)
      (lib.filterAttrs (_: e: e.source != null || e.text != null)
        (utils.enabled entries));

    # ── Hook wiring, derived from the bus ───────────────────────────────
    enabledHooks = utils.enabled ai.hooks;

    # Sorted so the rendered JSON (and therefore the managed file's store
    # hash) is stable across evaluations.
    hookNames = lib.sort (a: b: a < b) (lib.attrNames enabledHooks);

    mkHookEntry = name: let
      h = enabledHooks.${name};
    in
      lib.optionalAttrs (h.matcher != null) {matcher = h.matcher;}
      // {
        hooks = [
          ({
              type = "command";
              command = ''bash "$HOME/.claude/hooks/${name}"'';
            }
            // lib.optionalAttrs (h.timeout != null) {timeout = h.timeout;})
        ];
      };

    # event -> [entry], preserving name order within each event.
    hookSettings = lib.foldl' (acc: name: let
      ev = enabledHooks.${name}.event;
    in
      acc // {${ev} = (acc.${ev} or []) ++ [(mkHookEntry name)];}) {}
    hookNames;

    # Union of raw hooks a host may have put in managedSettings with the
    # bus-derived ones, per event.
    mergedHooks =
      lib.zipAttrsWith (_: lib.concatLists)
      [(cfg.managedSettings.hooks or {}) hookSettings];

    # ── Permission rules, derived from the bus ──────────────────────────
    # Each list a module contributed on `ai.permissions.<kind>` is unioned
    # with whatever the host put in managedSettings.permissions.<kind>;
    # other permission keys (defaultMode, …) pass through untouched.
    hostPermissions = cfg.managedSettings.permissions or {};
    mergePermissionList = kind:
      lib.optionalAttrs (ai.permissions.${kind} != []) {
        ${kind} = lib.unique ((hostPermissions.${kind} or []) ++ ai.permissions.${kind});
      };
    mergedPermissions =
      hostPermissions
      // mergePermissionList "allow"
      // mergePermissionList "ask"
      // mergePermissionList "deny";

    # ── Enforced policy, computed once at darwin level ──────────────────
    managedSettings =
      (removeAttrs cfg.managedSettings ["hooks" "permissions"])
      // lib.optionalAttrs (mergedPermissions != {}) {permissions = mergedPermissions;}
      // lib.optionalAttrs (mergedHooks != {}) {hooks = mergedHooks;}
      // {"$schema" = schemaUrl;};
    managedFile =
      pkgs.writeText "claude-code-managed-settings.json"
      (builtins.toJSON managedSettings);

    # ── Mutable defaults, written only when no valid live file exists ───
    seedSettings = cfg.seedSettings // {"$schema" = schemaUrl;};
    seedFile =
      pkgs.writeText "claude-code-seed-settings.json"
      (builtins.toJSON seedSettings);

    homeManagerConfig = utils.mkHomeManagerUser ({
      config,
      lib,
      ...
    }: let
      claudeDir = config.programs.claude-code.configDir;
      settingsPath = "${claudeDir}/settings.json";
      jq = "${pkgs.jq}/bin/jq";
    in {
      programs.claude-code = {
        enable = true;
        package = cfg.package;

        # Pull the shared `programs.mcp.servers` registry (populated by
        # modules/ai/mcp.nix) into Claude Code as a personal plugin.
        enableMcpIntegration = true;

        skills = contentOf ai.skills;
        agents = contentOf ai.agents;
        commands = contentOf ai.commands;
        rules = contentOf ai.rules;
        hooks = lib.mapAttrs (_: h: h.script) enabledHooks;
        plugins = lib.mapAttrs (_: p: p.source) (utils.enabled ai.plugins);
        context = ai.context;

        # Bus metadata (`enable`, `description`) is ours; everything else,
        # declared options and freeform keys alike, is Claude Code's
        # `.lsp.json` schema and passes through untouched.
        lspServers =
          lib.mapAttrs (_: s: removeAttrs s ["enable" "description"])
          (utils.enabled ai.lspServers);

        # `settings` intentionally NOT set — see header comment.
      };

      # Belt-and-braces: HM only renders settings.json when its `settings`
      # or `marketplaces` are non-empty, and we leave both empty. Keep the
      # guard anyway so a future HM change can never hand Claude Code a
      # read-only store symlink here; settings.json must stay a real
      # writable file owned by the app, seeded by the activation below.
      # (Disabled home.file entries are dropped before HM's collision/sanity
      # asserts, so this is collision-free.)
      home.file."${settingsPath}".enable = lib.mkForce false;

      home.activation.claudeCodeSeedSettings = config.lib.dag.entryAfter ["linkGeneration"] ''
        _settings=${lib.escapeShellArg settingsPath}
        # Single dry-run guard around ALL side effects: `switch --dry-run`
        # makes no writes.
        if [[ -v DRY_RUN ]]; then
          echo "would seed $_settings (default model) if absent; runtime keys stay untouched"
        else
          mkdir -p ${lib.escapeShellArg claudeDir}

          # Drop the stale read-only store symlink left by previous
          # generations so Claude Code can own a real file.
          if [ -L "$_settings" ]; then
            rm -f "$_settings"
          fi

          if [ -e "$_settings" ]; then
            # Live file present: leave runtime state alone. Self-heal only
            # if it is not a JSON object (e.g. Claude crashed mid-write) —
            # back it up and reseed rather than wedging the app.
            if ! ${jq} -e 'type == "object"' "$_settings" >/dev/null 2>&1; then
              cp -f "$_settings" "$_settings.corrupt.$(date +%s)" 2>/dev/null || true
              echo "claude-code: settings.json was not a JSON object; backed up and reseeded" >&2
              install -m 0600 ${seedFile} "$_settings"
            fi
          else
            install -m 0600 ${seedFile} "$_settings"
          fi
        fi
      '';
    });
  in
    lib.mkMerge [
      {
        # This module's own policy defaults. They are set with LEAF-level
        # mkDefault on purpose: `mkDefault { … }` on the whole attrset is
        # all-or-nothing — the moment a host defines any key of
        # managedSettings, a whole-attrset default would be dropped
        # entirely (module-system overrides are resolved per option before
        # attrsets are merged). Per-leaf defaults merge with host additions
        # and are individually overridable.
        applications.claude-code.managedSettings = {
          skipAutoPermissionPrompt = lib.mkDefault true;
          permissions.defaultMode = lib.mkDefault "auto";
        };
        applications.claude-code.seedSettings.model = lib.mkDefault "opus[1m]";
      }

      (utils.mkPlatformConfig {
        base = homeManagerConfig;

        # Root-owned enforced policy; Claude Code reads it with highest
        # precedence and never writes it, so a plain copy-on-activation is
        # conflict-free.
        darwin = {
          system.activationScripts.extraActivation.text = ''
            echo >&2 "installing Claude Code managed settings..."
            mkdir -p ${lib.escapeShellArg darwinManagedDir}
            install -m 0644 ${managedFile} ${lib.escapeShellArg (darwinManagedDir + "/managed-settings.json")}
          '';
        };

        nixos = {
          environment.etc."claude-code/managed-settings.json".source = managedFile;
        };

        # No root on generic linux to install /etc/claude-code/
        # managed-settings.json, so re-assert the enforced policy directly
        # into the user file after the seed step. Every `hooks.<event>`
        # array is unioned (not replaced) so a hook the user adds in-app via
        # /hooks survives the next switch alongside the enforced ones.
        linux = utils.mkHomeManagerUser ({
          config,
          lib,
          ...
        }: let
          settingsPath = "${config.programs.claude-code.configDir}/settings.json";
          jq = "${pkgs.jq}/bin/jq";
        in {
          home.activation.claudeCodeEnforceSettings = config.lib.dag.entryAfter ["claudeCodeSeedSettings"] ''
            _settings=${lib.escapeShellArg settingsPath}
            if [[ -v DRY_RUN ]]; then
              echo "would merge enforced policy into $_settings (no /etc/claude-code on generic linux)"
            else
              # The seed step already guaranteed a valid JSON object; stay
              # defensive anyway. Render to a sibling tmp + atomic rename so
              # a jq failure can never truncate the live file.
              _live='{}'
              if ${jq} -e 'type == "object"' "$_settings" >/dev/null 2>&1; then
                _live=$(cat "$_settings")
              fi
              _tmp=$(mktemp "$(dirname "$_settings")/.claude-settings.XXXXXX")
              if ${jq} -n \
                   --argjson   live "$_live" \
                   --slurpfile enf  ${managedFile} \
                   '$live * $enf[0]
                    | .hooks = ( ((($live.hooks // {}) | to_entries) + (($enf[0].hooks // {}) | to_entries))
                                 | group_by(.key)
                                 | map({key: .[0].key, value: (map(.value) | add | unique)})
                                 | from_entries )
                    | if (.hooks | length) == 0 then del(.hooks) else . end' > "$_tmp"; then
                chmod 0600 "$_tmp"
                mv -f "$_tmp" "$_settings"
              else
                rm -f "$_tmp"
                echo "claude-code: failed to merge enforced settings; left existing file untouched" >&2
              fi
            fi
          '';
        });
      })
    ])
