{...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    devShells = {
      default = pkgs.mkShell {
        packages = with pkgs.unstable; [bashInteractive git jq];
        shellHook = ''
          export EDITOR=nvim
          export NIX_CONFIG_MACHINE=${config.configuration.machine}
          # TOOD: change MODULE -> NAME
          export NIX_CONFIG_MODULE=${config.configuration.name}
        '';
      };
    };
  };
}
