# Secret resolution bus. See ./README.md.
#
# Declares `secrets.*` (options.nix): which CLI fetches secret VALUES at
# runtime. Consumers (e.g. modules/ai/mcp.nix) read
# `config.secrets.readCommand` and wrap programs with
# `utils.secrets.mkEnvWrapper`; nothing here depends on any consumer.
{...}: {
  imports = [
    ./options.nix
  ];
}
