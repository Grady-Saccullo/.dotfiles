{...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    devShells = {
      default = pkgs.mkShell {
        # sops/age/ssh-to-age: edit encrypted homelab secrets (see docs/homelab.md)
        packages = with pkgs.unstable; [bashInteractive git jq sops age ssh-to-age];
        shellHook = ''
          export EDITOR=nvim
        '';
      };
    };
  };
}
