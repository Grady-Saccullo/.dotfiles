{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;

  readCommandFor = {
    op = ["op" "read" "--no-newline"];
    rbw = ["rbw" "get"];
    bw = ["bw" "get" "password"];
  };
in {
  options.secrets = {
    backend = mkOption {
      type = types.nullOr (types.enum ["op" "rbw" "bw"]);
      default = null;
      example = "op";
      description = ''
        Secret manager CLI used to resolve secret references at runtime.
        Sets the default of `secrets.readCommand`.

        - `op`: 1Password CLI (`op read --no-newline op://Vault/item/field`).
          On macOS it ships with the 1Password desktop app.
        - `rbw`: unofficial Bitwarden CLI (`rbw get <item>`), from nixpkgs.
        - `bw`: official Bitwarden CLI (`bw get password <item>`), from nixpkgs.

        The CLI is looked up on `PATH` when a secret is read, not at build
        time; this module does not install it. `null` means no backend is
        configured: consumers that hold a secret reference fail evaluation
        with an assertion until one is chosen.
      '';
    };

    readCommand = mkOption {
      type = types.listOf types.str;
      default =
        if config.secrets.backend == null
        then []
        else readCommandFor.${config.secrets.backend};
      defaultText = lib.literalExpression ''
        {
          op = ["op" "read" "--no-newline"];
          rbw = ["rbw" "get"];
          bw = ["bw" "get" "password"];
        }.''${secrets.backend} or []
      '';
      example = lib.literalExpression ''["pass" "show"]'';
      description = ''
        Command that prints exactly one secret to stdout, given the secret
        reference as trailing argument(s). Derived from `secrets.backend`;
        override to use a custom backend or different flags. Consumers run
        it through `utils.secrets.mkEnvWrapper` when the program starts, so
        the resolved value never enters the Nix store.
      '';
    };
  };
}
