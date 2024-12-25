{inputs, ...}: final: prev: {
  unstable = import inputs.nixpkgs-unstable {
    system = final.system;
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = true;
    };
    overlays = [
      (self: super: {
        lua-language-server = super.lua-language-server.overrideAttrs (oldAttrs: {
          # currently there is an issue copy not existing in the std namespace
          # for apple sdk 11 now.
          # fix pulled from https://github.com/NixOS/nixpkgs/issues/367960
          postPatch =
            ''
              # filewatch tests are failing on darwin
              # this feature is not used in lua-language-server
              substituteInPlace 3rd/bee.lua/test/test.lua \
                --replace-fail 'require "test_filewatch"' ""

              # TEMP FIX: hack for compiling the old vendored fmt libraries with clang
              # error: std::copy is not in namespace std;
              # https://github.com/NixOS/nixpkgs/issues/367960
              sed -i 1i'#include <memory>' $(find 3rd -name color.h)

              # flaky tests on linux
              # https://github.com/LuaLS/lua-language-server/issues/2926
              substituteInPlace test/tclient/init.lua \
                --replace-fail "require 'tclient.tests.load-relative-library'" ""

              pushd 3rd/luamake
            ''
            # + lib.optionalString stdenv.hostPlatform.isDarwin (
            +
            # This package uses the program clang for C and C++ files. The language
            # is selected via the command line argument -std, but this do not work
            # in combination with the nixpkgs clang wrapper. Therefor we have to
            # find all c++ compiler statements and replace $cc (which expands to
            # clang) with clang++.
            ''
              sed -i compile/ninja/macos.ninja \
                -e '/c++/s,$cc,clang++,' \
                -e '/test.lua/s,= .*,= true,' \
                -e '/ldl/s,$cc,clang++,'
              sed -i scripts/compiler/gcc.lua \
                -e '/cxx_/s,$cc,clang++,'
            ''
            # Avoid relying on ditto (impure)
            + ''
              substituteInPlace compile/ninja/macos.ninja \
                --replace-fail "ditto" "rsync -a"

              substituteInPlace scripts/writer.lua \
                --replace-fail "ditto" "rsync -a"
            '';
          # );
        });
      })
    ];
  };
  wezterm-nightly = inputs.wezterm;
}
