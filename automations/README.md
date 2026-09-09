# ha-automations

TypeScript daemon on `home-assistant-js-websocket` for the stateful logic
that HA YAML fights you on. Built by `modules/homelab/automations.nix`.

First time:

```sh
cd automations && npm install              # creates package-lock.json
nix run nixpkgs#prefetch-npm-deps -- package-lock.json   # -> npmDepsHash
```

Put the hash in `hosts/homelab/default.nix` (`homelab.automations.npmDepsHash`)
and set `homelab.automations.enable = true`. The unit reads `HASS_URL` and
`HASS_TOKEN` from the `ha-automations.env` sops secret.
