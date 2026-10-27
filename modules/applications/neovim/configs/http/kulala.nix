{
  config,
  pkgs,
  utils,
  ...
}:
utils.mkNeovimModule {
  inherit config pkgs;
  path = ["http" "kulala"];
} ({vimPlugins, ...}: {
  plugins = [
    {
      plugin = vimPlugins.kulala-nvim.overrideAttrs (old: {
        # nixpkgs ships the grammar as parser/kulala_http.so but kulala looks for .dylib on macOS,
        # so it tries to rebuild the parser with a tree-sitter CLI we don't install.
        postPatch =
          (old.postPatch or "")
          + ''
            substituteInPlace lua/kulala/config/parser.lua \
              --replace-fail '"dylib"' '"so"'
          '';
      });
      config = builtins.readFile ./kulala-nvim.lua;
      type = "lua";
    }
  ];

  extraPackages = [
    pkgs.curl
  ];
})
