# Single source of truth for NixOS hosts. Consumed by:
#   flake.nix                      -> nixosConfigurations + flake checks
#   modules/nixos/sensible.nix     -> ssh known_hosts on every host
#   modules/applications/ssh       -> ~/.ssh/config on the Macs
#   modules/homelab/dns.nix        -> <name>.<domain> DNS rewrites
#   modules/homelab/monitoring.nix -> Prometheus scrape targets
#
# Adding a machine = one entry here + hosts/<name>/{default,hardware}.nix.
{
  homelab = {
    system = "x86_64-linux";
    user = "hackerman";
    address = "192.168.1.2";
    roles = ["dns" "home-automation" "monitoring"];
    # `ssh-keyscan -t ed25519 192.168.1.2` after install; null until then.
    sshHostKey = null;
  };

  # Next box. Uncomment once it exists; copy hosts/homelab/hardware.nix.
  # media = {
  #   system = "x86_64-linux";
  #   user = "hackerman";
  #   address = "192.168.1.3";
  #   roles = ["media" "dns"];   # second DNS server for redundancy
  #   sshHostKey = null;
  # };
}
