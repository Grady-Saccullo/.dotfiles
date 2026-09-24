# Auto-registers shared, tool-agnostic content that lives next to this file.
#
#   ./skills/<name>/SKILL.md   -> ai.skills.<name>
#   ./agents/<name>.md         -> ai.agents.<name>
#   ./commands/<name>.md       -> ai.commands.<name>
#   ./rules/<name>.md          -> ai.rules.<name>
#
# Dropping a directory/file in is enough; hosts can still opt out with
# `ai.<kind>.<name>.enable = false`. Flakes only see git-tracked files, so
# new content must be `git add`ed before it is picked up.
{lib, ...}: let
  entriesOf = dir:
    if builtins.pathExists dir
    then builtins.readDir dir
    else {};

  # Directories only: skills are folders holding SKILL.md.
  skillDirs = dir:
    lib.mapAttrs' (name: _: lib.nameValuePair name {source = dir + "/${name}";})
    (lib.filterAttrs (_: type: type == "directory") (entriesOf dir));

  # Regular *.md files only, keyed by basename without the extension.
  markdownFiles = dir:
    lib.mapAttrs' (file: _:
      lib.nameValuePair (lib.removeSuffix ".md" file) {source = dir + "/${file}";})
    (lib.filterAttrs (file: type: type == "regular" && lib.hasSuffix ".md" file)
      (entriesOf dir));
in {
  ai = {
    skills = skillDirs ./skills;
    agents = markdownFiles ./agents;
    commands = markdownFiles ./commands;
    rules = markdownFiles ./rules;
  };
}
