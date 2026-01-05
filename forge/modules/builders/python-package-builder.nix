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
                  build.pythonPackageBuilder = {
                    enable = lib.mkEnableOption ''
                      Python package builder.
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

              pythonPackageBuilderPkgs = lib.listToAttrs (
                map (pkg: rec {
                  name = pkg.name;
                  value = pkgs.callPackage (
                    # Derivation start
                    # buildPythonPackage doesn't support finalAttrs function.
                    # Passing thePackage to derivation is used as workaround.
                    { stdenv, thePackage }:
                    pkgs.python3Packages.buildPythonPackage (
                      {
                        pname = pkg.name;
                        version = pkg.version;
                        format = "pyproject";
                        src = sharedBuildAttrs.pkgSource pkg;
                        patches = pkg.source.patches;
                        build-system = pkg.build.pythonPackageBuilder.requirements.build-system;
                        dependencies = pkg.build.pythonPackageBuilder.requirements.dependencies;
                        passthru = sharedBuildAttrs.pkgPassthru pkg thePackage;
                        meta = sharedBuildAttrs.pkgMeta pkg;
                      }
                      // pkg.build.extraDrvAttrs
                      // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
                    )
                    # Derivation end
                  ) { thePackage = value; };
                }) (lib.filter (p: p.build.pythonPackageBuilder.enable == true) cfg)
              );
            in
            pythonPackageBuilderPkgs;
        };
      }
    );
  };
}
