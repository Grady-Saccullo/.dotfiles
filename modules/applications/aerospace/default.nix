{
  utils,
  config,
  lib,
  pkgs,
  me,
  ...
}:
utils.mkAppModule {
  path = "aerospace";
  inherit config;
  extraOptions = {
    package = lib.mkPackageOption pkgs "aerospace" {};
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Attrset forwarded to nix-darwin's services.aerospace.settings; set by the host module (see hosts/example/default.nix).";
    };
    path = lib.mkOption {
      type = lib.types.str;
      default = "/Users/${me.user}/Applications/Home Manager Apps/AeroSpace.app";
      description = "Path to the AeroSpace application that runs while `codesign.enable` is on; otherwise it runs from the Nix store";
    };
    bundleId = lib.mkOption {
      type = lib.types.str;
      default = "bobko.aerospace";
      readOnly = true;
      description = "macOS bundle identifier, for window-manager rules and the like";
    };
  };
} (cfg: let
  # With codesign on, the app comes from home-manager, where it can be signed and keep its
  # Accessibility grant; the system profile only gets the CLI.
  signed = config.codesign.enable;
  cli = pkgs.runCommand "aerospace-cli" {} ''
    mkdir -p $out/bin
    ln -s ${cfg.package}/bin/aerospace $out/bin/aerospace
  '';
  agent = config.launchd.user.agents.aerospace;
in
  utils.mkPlatformConfig {
    darwin = lib.mkMerge [
      {
        services.aerospace = {
          enable = true;
          package =
            if signed
            then cli
            else cfg.package;
          inherit (cfg) settings;
        };
      }
      (lib.mkIf signed {
        # nix-darwin's own command, started from the home-manager copy instead of the store.
        launchd.user.agents.aerospace.serviceConfig.ProgramArguments = lib.mkForce [
          "/bin/sh"
          "-c"
          "/bin/wait4path /nix/store && exec ${lib.replaceStrings ["${cli}/Applications/AeroSpace.app"] [(lib.escapeShellArg cfg.path)] agent.command}"
        ];
      })
      (lib.mkIf signed (utils.mkHomeManagerUser ({config, ...}: {
        home.packages = [cfg.package];
        # The agent's command no longer changes with the build, so launchd would keep the old one running.
        home.activation.restartAerospace = config.lib.dag.entryAfter ["codesignApps"] ''
          _marker=${lib.escapeShellArg "${config.xdg.stateHome}/aerospace-build"}
          if [[ "$(cat "$_marker" 2>/dev/null)" != "${cfg.package}" ]]; then
            run /bin/launchctl kickstart -k "gui/$(id -u)/${agent.serviceConfig.Label}" \
              || warnEcho "Could not restart AeroSpace; it runs the new build once it next starts."
            if [[ ! -v DRY_RUN ]]; then
              mkdir -p "$(dirname "$_marker")"
              printf '%s' ${cfg.package} >"$_marker"
            fi
          fi
        '';
      })))
    ];
    nixos = "aerospace is only supported on darwin";
    linux = "aerospace is only supported on darwin";
  })
