{...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    devShells = {
      default = pkgs.mkShell {
        packages = with pkgs; [bashInteractive git jq];
        shellHook = ''
          export EDITOR=nvim
        '';
      };
    };
  };
}
