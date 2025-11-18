{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "python-web";
  version = "0.0.1";
  description = "Python web application example built from GitHub source.";
  homePage = "https://github.com/imincik/python-web-example";
  mainProgram = "python-web";

  source = {
    git = "github:imincik/python-web-example/bd57b302e930f3b8b80448d2c08a3aac7d48e4ec";
    hash = "sha256-nSW5746+criXHPrxmJ+0zhJCMwl78eer03qQAvDIo5U=";
  };

  build.pythonAppBuilder = {
    enable = true;
    requirements.build-system = [
      pkgs.python3Packages.setuptools
    ];
    requirements.dependencies = [
      pkgs.python3Packages.flask
      pkgs.python3Packages.psycopg2
    ];
  };
}
