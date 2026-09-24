{lib, ...}: let
  inherit (lib) mkOption types;
in {
  options.shell = {
    aliases = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = lib.literalExpression ''{ j = "jj"; gst = "git status"; }'';
      description = ''
        Shell aliases contributed by application modules (git, jj, ...) and
        installed by every enabled shell module (zsh today). Values are plain
        alias bodies and must be sh/zsh-compatible.

        Entries are plain strings on purpose (no per-entry `enable`): a host
        overrides one with `shell.aliases.<name> = lib.mkForce "...";`. An
        entry cannot be removed by a host, so a contributor that expects
        hosts to want it gone should gate it itself.
      '';
    };

    init = mkOption {
      type = types.attrsOf types.lines;
      default = {};
      example = lib.literalExpression ''
        {
          git = '''
            function git_main_branch() { ... }
          ''';
        }
      '';
      description = ''
        Named shell init snippets (functions, completions, environment)
        contributed by application modules and appended to every enabled
        shell's init file. Snippets must be sh/zsh-compatible. They are
        concatenated in attribute-name order, so the generated file is
        deterministic and a snippet that must run before another can be
        named accordingly. Hosts drop one with
        `shell.init.<name> = lib.mkForce "";`.
      '';
    };
  };
}
