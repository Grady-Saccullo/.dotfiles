{
  config,
  lib,
  pkgs,
  utils,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (utils.secrets) readCommandFor mkReadCommandHook;
  cfg = config.secrets;
in {
  options.secrets = {
    backend = mkOption {
      type = types.nullOr (types.enum ["op" "rbw" "bw"]);
      default = null;
      example = "op";
      description = ''
        Preset for `secrets.readCommand`, for secrets kept in one of these password managers:

        - `op`: 1Password CLI (`op read --no-newline op://Vault/item/field`).
          On macOS it ships with the 1Password desktop app.
        - `rbw`: unofficial Bitwarden CLI (`rbw get <item>`), from nixpkgs.
        - `bw`: official Bitwarden CLI (`bw get password <item>`), from nixpkgs. Needs an unlocked
          vault in the environment (`BW_SESSION`).

        The CLI is looked up on `PATH` when a secret is read; this module does not install it.
        `null` means no preset. Anything else, or no password manager at all, goes in `secrets.hook`.
      '';
    };

    readCommand = mkOption {
      type = types.listOf types.str;
      default =
        if cfg.backend == null
        then []
        else readCommandFor.${cfg.backend};
      defaultText = lib.literalExpression ''
        {
          op = ["op" "read" "--no-newline"];
          rbw = ["rbw" "get"];
          bw = ["bw" "get" "password" "--nointeraction"];
        }.''${secrets.backend} or []
      '';
      example = lib.literalExpression ''["pass" "show"]'';
      description = ''
        Command that prints exactly one secret to stdout, given the secret reference as trailing
        argument(s). It must not prompt. When set, `secrets.hook` defaults to a hook that runs it
        once per reference.
      '';
    };

    hook = mkOption {
      type = types.nullOr types.package;
      default =
        if cfg.readCommand == []
        then null
        else
          mkReadCommandHook {
            inherit pkgs;
            inherit (cfg) readCommand;
          };
      defaultText = lib.literalExpression ''
        if secrets.readCommand == [] then null
        else utils.secrets.mkReadCommandHook { inherit pkgs; inherit (config.secrets) readCommand; }
      '';
      example = lib.literalExpression "pkgs.callPackage ./my-secrets-hook.nix {}";
      description = ''
        Program that reads this host's secret values: a package whose `meta.mainProgram` takes a
        batch of references on stdin and prints their values on stdout, as described in
        modules/secrets/README.md. Used for `{ secret = ...; }` references at program start and,
        unless `switch.hook` says otherwise, for the switch steps' secrets at switch time.
      '';
    };
  };
}
