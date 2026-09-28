{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;

  step = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether `nix run .#switch` runs this step.";
      };
      phase = mkOption {
        type = types.enum ["preBuild" "postSwitch"];
        description = ''
          When the step runs: `preBuild` before the system is built, `postSwitch` after the switch
          and the package diff.
        '';
      };
      package = mkOption {
        type = types.package;
        description = ''
          The step's program: its `meta.mainProgram` runs with the step input (JSON) on stdin, as
          described in modules/switch/README.md.
        '';
      };
      secrets = mkOption {
        type = types.attrsOf (types.either types.str (types.listOf types.str));
        default = {};
        example = {token = "my-cache-token";};
        description = ''
          Label to secret reference. `switch.hook` reads them before the build and the step gets the
          values under `secrets.<label>`; a value the hook could not read is missing.
        '';
      };
      settings = mkOption {
        type = (pkgs.formats.json {}).type;
        default = {};
        example = {cache = "my-cache";};
        description = "Configuration that is not secret, passed to the step as it is under `settings`.";
      };
    };
  };
in {
  options.switch = {
    hook = mkOption {
      type = types.nullOr types.package;
      default = config.secrets.hook or null;
      defaultText = lib.literalExpression "config.secrets.hook";
      example = lib.literalExpression "pkgs.callPackage ./my-secrets-hook.nix {}";
      description = ''
        Secrets hook (modules/secrets/README.md) that `nix run .#switch` asks for every step's
        secrets, in one call, before the build.
      '';
    };

    steps = mkOption {
      type = types.attrsOf step;
      default = {};
      example = lib.literalExpression ''
        {
          push-to-cache = {
            phase = "postSwitch";
            package = pkgs.callPackage ./push-to-cache.nix {};
            secrets.token = "my-cache-token";
            settings.cache = "https://cache.example.com";
          };
        }
      '';
      description = ''
        Programs `nix run .#switch` runs before the build and after the switch, in name order. A
        failing step only prints a warning. See modules/switch/README.md.
      '';
    };

    plan = mkOption {
      type = types.attrs;
      internal = true;
      readOnly = true;
      description = "What apps/switch reads with `nix eval --json`.";
    };

    tools = mkOption {
      type = types.package;
      internal = true;
      readOnly = true;
      description = "The enabled steps' packages and the hook they need, for a single `nix build`.";
    };
  };
}
