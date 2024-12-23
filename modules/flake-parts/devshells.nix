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
        '';
      };
    };
  };
}
