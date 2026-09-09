# sops-nix wiring. Secrets live *encrypted* in ./secrets inside this public
# repo (age recipients: your personal key + each host's ssh-derived key, see
# .sops.yaml). At activation sops-nix decrypts them into /run/secrets with
# the ownership each service module asks for.
{
  inputs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.homelab.secrets;
in {
  imports = [inputs.sops-nix.nixosModules.sops];

  options.homelab.secrets = {
    enable = mkEnableOption "sops-nix managed secrets";
    file = mkOption {
      type = types.path;
      description = "Encrypted sops yaml file holding this host's secrets.";
    };
    cachixNetrc = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Install /etc/nix/netrc from the `nix/netrc` secret so builds on this
        host can pull from the private cachix cache declared in flake.nix
        (otherwise every build warns HTTP 401). Same 0644 rationale as the
        README's macOS setup.
      '';
    };
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = cfg.file;
      # The host's age identity is derived from its ssh host key. Ship that
      # key at install time with `nixos-anywhere --extra-files` (see the
      # runbook) so even the first activation can decrypt.
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      secrets."nix/netrc" = mkIf cfg.cachixNetrc {
        path = "/etc/nix/netrc";
        mode = "0644";
      };
    };
  };
}
