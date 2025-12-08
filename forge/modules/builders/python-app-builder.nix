{
  inputs,
  config,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options = {
    perSystem = mkPerSystemOption (
      { config, pkgs, sharedBuildAttrs, ... }:
      {
        options = {
          forge.packages = lib.mkOption {
            type = lib.types.listOf (
              lib.types.submodule {
                options = {
                  build.pythonAppBuilder = {
                    enable = lib.mkEnableOption ''
                      Python application builder.
                    '';
                    requirements = {
                      build-system = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                      };
                      dependencies = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                      };
                    };
                  };
                };
              }
            );
          };
        };

        config = {
          packages =
            let
              cfg = config.forge.packages;

              pythonAppBuilderPkgs = lib.listToAttrs (
                map (pkg: rec {
                  name = pkg.name;
                  value = pkgs.callPackage (
                    # Derivation start
                    # buildPythonPackage doesn't support finalAttrs function.
                    # Passing thePackage to derivation is used as workaround.
                    { stdenv, thePackage }:
                    pkgs.python3Packages.buildPythonApplication (
                      {
                        pname = pkg.name;
                        version = pkg.version;
                        format = "pyproject";
                        src = sharedBuildAttrs.pkgSource pkg;
                        build-system = pkg.build.pythonAppBuilder.requirements.build-system;
                        dependencies = pkg.build.pythonAppBuilder.requirements.dependencies;
                        passthru = sharedBuildAttrs.pkgPassthru pkg thePackage;
                        meta = sharedBuildAttrs.pkgMeta pkg;
                      }
                      // pkg.build.extraDrvAttrs
                      // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
                    )
                    # Derivation end
                  ) { thePackage = value; };
                }) (lib.filter (p: p.build.pythonAppBuilder.enable == true) cfg)
              );
            in
            pythonAppBuilderPkgs;
        };
      }
    );
  };
}
