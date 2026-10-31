# Re-signs the ad-hoc signed apps home-manager installs with one local certificate after every switch,
# so macOS privacy grants survive rebuilds. See ./README.md.
{
  config,
  lib,
  pkgs,
  utils,
  me,
  ...
}: let
  cfg = config.codesign;
  copyApps = config.home-manager.users.${me.user}.targets.darwin.copyApps;
  # nix-darwin's copies of `environment.systemPackages` apps are root's, so they are only reported.
  appDirs = ["/Users/${me.user}/${copyApps.directory}" "/Applications/Nix Apps"];
  # macOS's own codesign, security and openssl, ahead of any Nix build of the same name.
  path = "/usr/bin:/bin";
  signApps = pkgs.writeShellScript "codesign-apps" ''
    PATH=${path}:$PATH exec ${pkgs.bash}/bin/bash -e ${./sign-apps.sh} ${lib.escapeShellArgs ([cfg.identity] ++ appDirs)}
  '';
  setup = pkgs.writeShellScriptBin "codesign-setup" ''
    PATH=${path}:$PATH ${pkgs.bash}/bin/bash -e ${./create-identity.sh} ${lib.escapeShellArg cfg.identity} || exit
    exec ${signApps}
  '';
in {
  options.codesign = {
    enable = lib.mkEnableOption "re-signing every ad-hoc signed app home-manager installs with `codesign.identity` after each switch, so macOS privacy grants survive rebuilds (macOS only)";

    identity = lib.mkOption {
      type = lib.types.str;
      default = "Nix self-signed";
      description = ''
        Name of the code-signing identity in the login keychain that apps are signed with.
        `nix run .#codesign-setup <host>` creates it.
      '';
    };

    setup = lib.mkOption {
      type = lib.types.package;
      internal = true;
      readOnly = true;
      default = setup;
      description = "What `nix run .#codesign-setup <host>` runs: creates `codesign.identity` if it is missing, then signs the apps.";
    };
  };

  config = lib.mkIf cfg.enable (utils.mkPlatformConfig {
    darwin = lib.mkMerge [
      {
        assertions = [
          {
            assertion = copyApps.enable;
            message = "codesign.enable needs home-manager's targets.darwin.copyApps: linked apps stay in the read-only Nix store.";
          }
        ];
      }
      (utils.mkHomeManagerUser ({config, ...}: {
        # copyApps puts the store's ad-hoc signed build back on every switch.
        home.activation.codesignApps = config.lib.dag.entryAfter ["copyApps"] ''
          run ${signApps} || warnEcho "Not every ad-hoc signed app was re-signed (see above); \`nix run .#codesign-setup <host>\` retries."
        '';
      }))
    ];
  });
}
