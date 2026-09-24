# Browser-agnostic extension bus. See ./README.md.
#
# Declares `browser.*` (options.nix). App modules that ship a browser
# extension (1password, bitwarden, raycast, ...) write to it; browser modules
# (modules/applications/brave) read it. Nothing here depends on any browser.
{...}: {
  imports = [
    ./options.nix
  ];
}
