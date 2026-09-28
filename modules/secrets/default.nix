# Secret resolution bus (./README.md). Consumers such as modules/ai/mcp.nix read `config.secrets.hook`
# and wrap programs with `utils.secrets.mkEnvWrapper`; nothing here depends on any consumer.
{...}: {
  imports = [
    ./options.nix
  ];
}
