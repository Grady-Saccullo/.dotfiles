# Shell-agnostic alias/init bus. See ./README.md.
#
# Declares `shell.*` (options.nix). App modules that ship aliases or shell
# functions (git, jj, ...) write to it; shell modules
# (modules/applications/zsh) read it. Nothing here depends on any shell.
{...}: {
  imports = [
    ./options.nix
  ];
}
