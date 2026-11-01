# home-manager plugin entries that load `plugin` through lz.n on a trigger instead of at startup.
# nixpkgs `dependencies` follow the plugin into pack/*/opt, so they are packadd'ed first.
{lib}: {
  plugin,
  event ? [],
  ft ? [],
  cmd ? [],
  keys ? [],
  before ? [],
  after ? [],
  beforeConfig ? "",
  config ? "",
}: let
  name = lib.getName plugin;
  closure = ps: lib.unique (lib.concatMap (p: closure (p.dependencies or []) ++ [p]) ps);
  deps = lib.subtractLists [plugin] (closure (before ++ (plugin.dependencies or [])));
  afterDeps = lib.subtractLists ([plugin] ++ deps) (closure after);

  str = s: ''"${s}"'';
  list = xs: "{ ${lib.concatMapStringsSep ", " str xs} }";
  keyLhs = k:
    if builtins.isString k
    then k
    else k.lhs;
  key = k:
    if builtins.isString k
    then str k
    else "{ ${str k.lhs}${lib.optionalString (k ? mode) ", mode = ${list k.mode}"}${lib.optionalString (k ? desc) ", desc = ${str k.desc}"} }";
  triggers = lib.concatStringsSep " " (
    map (e: "event:${e}") event
    ++ map (f: "ft:${f}") ft
    ++ map (c: "cmd:${c}") cmd
    ++ map (k: "key:${keyLhs k}") keys
  );
  packadd = lib.concatMapStrings (p: "require(\"hm-lazy\").packadd(${str (lib.getName p)})\n");
  register = how: lib.concatMapStrings (p: "require(\"hm-lazy\").register(${str (lib.getName p)}, ${str how})\n");

  lua = ''
    ${register triggers [plugin]}
    ${register "with ${name}" (deps ++ afterDeps)}
    require("lz.n").load({
      ${str name},
      ${lib.optionalString (event != []) "event = ${list event},"}
      ${lib.optionalString (ft != []) "ft = ${list ft},"}
      ${lib.optionalString (cmd != []) "cmd = ${list cmd},"}
      ${lib.optionalString (keys != []) "keys = { ${lib.concatMapStringsSep ", " key keys} },"}
      before = function()
        ${packadd deps}
        ${beforeConfig}
      end,
      after = function()
        ${packadd afterDeps}
        ${config}
      end,
    })
  '';
in
  map (p: {
    plugin = p;
    optional = true;
  }) (deps ++ afterDeps)
  ++ [
    {
      inherit plugin;
      optional = true;
      type = "lua";
      config = lua;
    }
  ]
