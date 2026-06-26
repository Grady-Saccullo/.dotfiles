{
  utils,
  config,
  lib,
  pkgs,
  me,
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
  #                            All enforced policy lives here: everything
  #                            modules contribute to
  #                            `programs.claude-code.settings` (this module's
  #                            permission policy, jj's PreToolUse hook, …).
  #                            Hooks and permissions merge across scopes at
  #                            runtime, so user-added /hooks in settings.json
  #                            coexist with these. Removing a key here
  #                            removes the policy — no stale keys linger in
  #                            the user file.
  #
  #   ~/.claude/settings.json — a real writable file owned by Claude Code.
  #                            We only SEED it (default model) when it is
  #                            absent, a stale store symlink, or corrupt;
  #                            runtime state (model via /model, effort,
  #                            theme, …) is otherwise never touched.
  #
  # `model` intentionally stays OUT of `programs.claude-code.settings`: in
  # managed-settings it would pin the startup model on every launch, whereas
  # as a seed the /model choice persists across sessions and rebuilds.
  #
  # Note: managed-settings.json is machine-wide (all users). On darwin it is
  # not removed if this module is disabled — delete it by hand in that case
  # (NixOS's environment.etc cleans up after itself).
  schemaUrl = "https://json.schemastore.org/claude-code-settings.json";
  darwinManagedDir = "/Library/Application Support/ClaudeCode";
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
  } (cfg: let
    # The full cross-module merge of programs.claude-code.settings (our
    # policy keys + jj's PreToolUse hook), read back from the evaluated
    # home-manager config and rendered into managed-settings.json below.
    managedSettings =
      config.home-manager.users.${me.user}.programs.claude-code.settings
      // {"$schema" = schemaUrl;};
    managedFile =
      pkgs.writeText "claude-code-managed-settings.json"
      (builtins.toJSON managedSettings);

    homeManagerConfig = utils.mkHomeManagerUser ({
      config,
      lib,
      ...
    }: let
      # Derive paths from configDir (default ~/.claude, absolute) so the
      # disable-key and the activation path can never desync if configDir is
      # ever repointed.
      claudeDir = config.programs.claude-code.configDir;
      settingsPath = "${claudeDir}/settings.json";

      # Mutable defaults, written only when no valid live file exists.
      seedSettings = {
        "$schema" = schemaUrl;
        model = "opus[1m]";
      };
      seedFile =
        pkgs.writeText "claude-code-seed-settings.json"
        (builtins.toJSON seedSettings);

      jq = "${pkgs.jq}/bin/jq";
    in {
      programs.claude-code = {
        enable = true;
        package = pkgs.llm-agents.claude-code;
        # ENFORCED policy: rendered into the root-owned managed-settings.json
        # (see header comment), NOT into ~/.claude/settings.json. `model` is
        # omitted on purpose — it is seeded below so /model choices persist.
        settings = {
          skipAutoPermissionPrompt = true;
          permissions.defaultMode = "auto";
        };
        skills =
          lib.mapAttrs (_: meta: meta.source)
          (lib.filterAttrs (name: _: cfg.skills.${name}.enable) ownedSkills);
      };

      # Suppress the read-only /nix/store symlink; settings.json is a real
      # writable file owned by Claude Code, seeded by the activation below.
      # (Disabled home.file entries are dropped before HM's collision/sanity
      # asserts, so this is collision-free.)
      home.file."${settingsPath}".enable = lib.mkForce false;

      home.activation.claudeCodeSeedSettings =
        config.lib.dag.entryAfter ["linkGeneration"] ''
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
    utils.mkPlatformConfig {
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
      # into the user file after the seed step. The PreToolUse array is
      # unioned (not replaced) so a hook the user adds in-app via /hooks
      # survives the next switch alongside the enforced jj hook.
      linux = utils.mkHomeManagerUser ({
        config,
        lib,
        ...
      }: let
        settingsPath = "${config.programs.claude-code.configDir}/settings.json";
        jq = "${pkgs.jq}/bin/jq";
      in {
        home.activation.claudeCodeEnforceSettings =
          config.lib.dag.entryAfter ["claudeCodeSeedSettings"] ''
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
                    | ((($live.hooks.PreToolUse // []) + ($enf[0].hooks.PreToolUse // [])) | unique) as $pt
                    | if ($pt | length) > 0 then .hooks.PreToolUse = $pt else . end' > "$_tmp"; then
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
