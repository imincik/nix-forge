{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "requests";
  version = "2.32.5";
  description = "Python HTTP library for humans.";
  homePage = "https://requests.readthedocs.io";
  mainProgram = ""; # No main program - this is a library

  source = {
    git = "github:psf/requests/v2.32.5";
    hash = "sha256-cEBalMFoYFaGG8M48k+OEBvzLegzrTNP1NxH2ljP6qg=";
  };

  build.pythonPackageBuilder = {
    enable = true;
    requirements = {
      build-system = [
        pkgs.python3Packages.setuptools
      ];
      dependencies = [
        pkgs.python3Packages.charset-normalizer
        pkgs.python3Packages.idna
        pkgs.python3Packages.urllib3
        pkgs.python3Packages.certifi
      ];
    };
    importsCheck = [
      "requests"
    ];
  };

  test.script = ''
    python -c "import requests; print(requests.__version__)" | grep "2.32.5"
    python -c "import requests; assert hasattr(requests, 'get')"
    python -c "import requests; assert hasattr(requests, 'post')"
  '';
}
