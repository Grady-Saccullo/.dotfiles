# python-matter-server for the HA `matter` integration. Pair Matter
# devices from HA at ws://127.0.0.1:5580/ws. Thread border routing needs a
# Thread radio and is out of scope here.
{
  utils,
  config,
  ...
}:
utils.mkHomelabModule {
  path = "matter";
  inherit config;
} (cfg: {
  services.matter-server = {
    enable = true;
    port = 5580;
  };
})
