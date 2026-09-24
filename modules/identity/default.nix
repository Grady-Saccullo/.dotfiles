# Tool-agnostic identity bus. See ./README.md.
#
# Declares `identity.*` (options.nix). Host configs set it; every module that
# needs a name/email pair (git, jj, later gh / AI context) reads it. Nothing
# here depends on any application module.
{...}: {
  imports = [
    ./options.nix
  ];
}
