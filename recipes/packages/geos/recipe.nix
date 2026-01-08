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

  build.standardBuilder = {
    enable = true;
    requirements.native = [
      pkgs.cmake
      pkgs.ninja
    ];
  };

  test.script = ''
    geosop | grep -E "geosop - GEOS 1000.0.0dev"
  '';
}
