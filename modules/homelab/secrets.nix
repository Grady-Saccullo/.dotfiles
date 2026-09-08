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
  };

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = cfg.file;
      # Derive the host's age identity from its ssh host key, so no extra
      # key material has to be provisioned onto the box.
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    };
  };
}
