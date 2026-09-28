# Cachix login and push for `nix run .#switch`. Hosts set token references; apps/switch asks
# `cachix.hook` for both in one call at switch time, so no token ever enters Nix.
{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  cfg = config.cachix;
  secretRef = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
  refs = lib.filterAttrs (_: ref: ref != null) {
    read = cfg.readToken;
    push = cfg.pushToken;
  };
in {
  options.cachix = {
    cache = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "my-cache";
      description = ''
        Cachix cache that `nix run .#switch` logs in to and pushes the built system to. Downloading
        from it also needs the cache in the flake's `nixConfig`, which a module cannot set.
      '';
    };
    backend = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["op" "rbw" "bw"]);
      default = config.secrets.backend;
      defaultText = lib.literalExpression "config.secrets.backend";
      example = "rbw";
      description = ''
        Preset for `cachix.hook`, like `secrets.backend`. Only needed when the tokens are kept in a
        different password manager than the host's other secrets.
      '';
    };
    hook = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default =
        if cfg.backend == config.secrets.backend
        then config.secrets.hook
        else if cfg.backend == null
        then null
        else
          utils.secrets.mkReadCommandHook {
            inherit pkgs;
            readCommand = utils.secrets.readCommandFor.${cfg.backend};
          };
      defaultText = lib.literalExpression ''
        config.secrets.hook, or a hook for the `cachix.backend` preset when that differs from `secrets.backend`
      '';
      example = lib.literalExpression "pkgs.callPackage ./my-secrets-hook.nix {}";
      description = ''
        Secrets hook (modules/secrets/README.md) that `nix run .#switch` asks for both tokens, in one
        call, before building.
      '';
    };
    readToken = lib.mkOption {
      type = lib.types.nullOr secretRef;
      default = null;
      example = "my-cache-read";
      description = ''
        Reference to a read-only token, passed to `cachix.hook` as it is. `nix run .#switch` writes the
        token to the `machine <cache>.cachix.org` line of `nix.settings.netrc-file` before building.
      '';
    };
    pushToken = lib.mkOption {
      type = lib.types.nullOr secretRef;
      default = null;
      example = "my-cache-push";
      description = ''
        Reference to a token with write access, used only for `cachix push` after a switch. When
        unset, the push uses `CACHIX_AUTH_TOKEN` from the environment if it is set.
      '';
    };
    switchConfig = lib.mkOption {
      type = lib.types.attrs;
      internal = true;
      readOnly = true;
      description = "What apps/switch reads through `nix eval`.";
    };
  };

  config = {
    cachix.switchConfig = {
      inherit (cfg) cache;
      inherit refs;
      netrcFile = config.nix.settings.netrc-file or "/etc/nix/netrc";
      hook =
        if cfg.hook == null
        then null
        else lib.getExe cfg.hook;
    };

    assertions = [
      {
        assertion = refs == {} || cfg.cache != null;
        message = "cachix.readToken / cachix.pushToken are set but cachix.cache is not.";
      }
      {
        assertion = refs == {} || cfg.hook != null;
        message = ''
          cachix.readToken / cachix.pushToken are set but there is nothing to read them with.
          Set secrets.hook (or a preset: secrets.backend) on this host; see modules/secrets/README.md.
        '';
      }
    ];
  };
}
