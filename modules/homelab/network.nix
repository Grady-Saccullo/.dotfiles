# Host networking: static address on the Infra VLAN (untagged), the IoT
# VLAN tagged into a bridge that only the HA VM attaches to. The host has
# no address on the IoT side; UniFi's zone firewall does the routing.
{
  config,
  lib,
  ...
}: let
  inherit (config.homelab) lan iot;
  vlanIf = "${lan.interface}.${toString iot.vlan}";
in {
  networking = {
    useDHCP = false;
    interfaces.${lan.interface}.ipv4.addresses = [
      {
        address = lan.address;
        prefixLength = 24;
      }
    ];
    defaultGateway = lan.gateway;
    # resolves through the local Blocky instance
    nameservers = ["127.0.0.1"];

    vlans.${vlanIf} = {
      id = iot.vlan;
      interface = lan.interface;
    };
    bridges.${iot.bridge}.interfaces = [vlanIf];
  };

  # Bridged frames for the VM must not be run through the host firewall.
  boot.kernelModules = ["br_netfilter"];
  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
    "net.bridge.bridge-nf-call-arptables" = 0;
  };

  services.resolved.enable = false;
}
