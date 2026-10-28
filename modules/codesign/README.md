# `codesign` — keep macOS privacy grants across rebuilds

macOS stores a privacy grant (Full Disk Access, Accessibility, access to another app's data) against
the app's code signature. An app Nix builds from source, such as WezTerm, is only ad-hoc signed, so
macOS knows it by a hash of that exact build: every rebuild looks like a new app, and the grant
silently stops applying. When the app is your terminal, anything you run from it loses access too,
including `nix run .#switch` writing into another app's data folder.

With `codesign.enable = true`, every switch re-signs the ad-hoc signed apps in
`~/Applications/Home Manager Apps` with one self-signed certificate in your login keychain, right
after home-manager copies them there. macOS then knows each app by its bundle id and that
certificate, which stay the same from build to build, so a grant given once keeps working.

Apps their developer signed (Brave, Slack, the JetBrains IDEs, …) are never touched. Their
signature is already stable, and they carry entitlements tied to the developer's account
(keychain groups, passkeys, associated domains) that stop working under any other signature.

## Options

| Option | Default | What it does |
| --- | --- | --- |
| `codesign.enable` | `false` | Re-sign every ad-hoc signed app home-manager installs, after each switch. |
| `codesign.identity` | `"Nix self-signed"` | Name of the code-signing identity in the login keychain. |

The switch prints each app it signs. An app that cannot be signed keeps its ad-hoc signature and
the switch prints a warning; it does not fail. Ad-hoc signed apps in `/Applications/Nix Apps`
(nix-darwin's `environment.systemPackages`) belong to root and cannot be re-signed, so the switch
names them instead: install those with home-manager to have them signed.

It needs home-manager's `targets.darwin.copyApps`, the default from state version 25.11: apps
linked from the Nix store cannot be re-signed.

## Apps that need more than a signature

An app macOS starts on its own, from a launch agent, must start from the signed copy rather than
from the Nix store. AeroSpace does that while `codesign.enable` is on: it is installed through
home-manager, its launch agent starts `~/Applications/Home Manager Apps/AeroSpace.app`, it restarts
after a switch that signed a new build, and the system profile only keeps the `aerospace` CLI.

## One-time setup on each Mac

1. In your flake, run `nix run .#codesign-setup <host>` (add `--local` to use `~/.dotfiles`, as
   with `switch`). It creates the certificate (`codesign.identity`) in the login keychain if it is
   missing, then signs the apps. It needs no switch first, so it also gets you out of a switch that
   fails because your terminal lost its grant. The first signing asks whether `codesign` may use
   the new key: enter your login password and choose **Always Allow**, or every switch asks again.
2. Quit and reopen each signed app.
3. Grant each app its permissions again, once. In System Settings > Privacy & Security, remove an
   existing entry with **–** and add the app again with **+**. Switching the toggle off and on keeps
   the old ad-hoc signature, so the grant would still not apply.

The certificate exists only in this Mac's keychain and nothing trusts it; macOS only compares it
from one build to the next. It lasts 20 years. Deleting it (or renaming `codesign.identity`) means
repeating the setup.
