# NUT for the CyberPower UPS on USB. netserver mode so Home Assistant (in
# the IoT VLAN) and Prometheus can read it; upsmon shuts this host down
# cleanly on low battery. BIOS "power on after AC loss" brings it back.
{
  utils,
  config,
  lib,
  ...
}:
utils.mkHomelabModule {
  path = "ups";
  inherit config;
} (cfg: let
  inherit (config.homelab) lan;
in {
  sops.secrets."nut/upsmon_password" = {};
  sops.secrets."nut/hass_password" = {};

  power.ups = {
    enable = true;
    mode = "netserver";
    ups.cp1500 = {
      driver = "usbhid-ups";
      port = "auto";
      directives = [
        "vendorid = 0764"
        "productid = 0501"
        "pollinterval = 15"
      ];
    };
    upsd.listen = [
      {address = "127.0.0.1";}
      {address = lan.address;}
    ];
    users = {
      upsmon = {
        passwordFile = config.sops.secrets."nut/upsmon_password".path;
        upsmon = "primary";
      };
      hass = {
        passwordFile = config.sops.secrets."nut/hass_password".path;
        upsmon = "secondary";
      };
    };
    upsmon.monitor.cp1500 = {
      user = "upsmon";
      powerValue = 1;
      type = "master";
    };
  };

  # 26.05: the driver can race USB enumeration at boot
  systemd.services.upsdrv.serviceConfig = {
    Restart = "on-failure";
    RestartSec = 10;
  };

  networking.firewall.allowedTCPPorts = [3493];
})
