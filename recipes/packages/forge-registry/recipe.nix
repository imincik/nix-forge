{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "forge-registry";
  version = "0.1.0";
  description = "OCI-compliant container registry for Nix Forge.";
  homePage = "https://github.com/imincik/nix-forge-registry";
  mainProgram = "forge-registry";

  source = {
    git = "github:imincik/nix-forge-registry/master";
    hash = "sha256-rQI1i0l+c8tyt4qSWwSFDPuyO6/euDCvjWSoTk1JFPU=";
  };

  build.pythonAppBuilder = {
    enable = true;
    requirements.build-system = [
      pkgs.python3Packages.setuptools
      pkgs.python3Packages.wheel
    ];
    requirements.dependencies = [
      pkgs.python3Packages.flask
    ];
    requirements.optional-dependencies = {
      production = [
        pkgs.python3Packages.gunicorn
      ];
    };
    importsCheck = [
      "app"
      "registry"
    ];
  };

  build.extraDrvAttrs =
    # Python environment for production deployment
    let
      pythonEnv = pkgs.python3.withPackages (
        ps:
        pkgs.mypkgs.forge-registry.dependencies
        ++ pkgs.mypkgs.forge-registry.optional-dependencies.production
      );
    in
    {
      passthru.prodEnv = pkgs.symlinkJoin {
        name = "forge-registry-prod-env";
        paths = [
          pythonEnv
          pkgs.mypkgs.forge-registry
        ];
      };
    };
}
