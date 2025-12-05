{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "hello";
  version = "2.12.1";
  description = "Hello package built from source code tarball.";
  homePage = "https://www.gnu.org/software/hello";
  mainProgram = "hello";

  source = {
    url = "mirror://gnu/hello/hello-2.12.1.tar.gz";
    hash = "sha256-jZkUKv2SV28wsM18tCqNxoCZmLxdYH2Idh9RLibH2yA=";
  };

  build.standardBuilder = {
    enable = true;
  };

  test.script = ''
    hello | grep "Hello, world"
  '';
}
