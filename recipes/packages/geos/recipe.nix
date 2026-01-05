{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "geos";
  version = "1000.0.0";
  description = "GEOS package built from GitHub source with version set using custom patch.";
  homePage = "https://libgeos.org";
  mainProgram = "geosop";

  source = {
    git = "github:libgeos/geos/883f237d1ecbf49f8efd09905df05814783c5b50";
    hash = "sha256-enHSmHW8bgRIv33cQrlllF6rbrCkXfqQilcu53LQiRE=";
    patches = [
      ./version-1000.patch
    ];
  };

  build.plainBuilder = {
    enable = true;
    requirements.native = [
      pkgs.cmake
      pkgs.ninja
    ];
    configure = ''
      mkdir build && cd build

      cmake ''${CMAKE_ARGS} \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_INSTALL_PREFIX=$out \
        ..
    '';
    build = ''
      make -j ''$NIX_BUILD_CORES
    '';
    check = ''
      ctest --output-on-failure
    '';
    install = ''
      make install -j ''$NIX_BUILD_CORES
    '';
  };

  test.script = ''
    geosop | grep -E "geosop - GEOS 1000.0.0dev"
  '';
}
