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
                      Python application builder for executable Python programs.

                      Uses buildPythonApplication which prevents the package from being used as a dependency'';
                    requirements = {
                      build-system = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                        description = "PEP-517 build system dependencies.";
                        example = lib.literalExpression "[ pkgs.python3Packages.setuptools pkgs.python3Packages.wheel ]";
                      };
                      dependencies = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                        description = "Runtime dependencies (PEP-621).";
                        example = lib.literalExpression "[ pkgs.python3Packages.click pkgs.python3Packages.requests ]";
                      };
                      optional-dependencies = lib.mkOption {
                        type = lib.types.attrsOf (lib.types.listOf lib.types.package);
                        default = { };
                        description = ''
                          PEP-621 optional dependencies (extras).

                          These are additional dependencies that can be installed optionally.
                        '';
                        example = lib.literalExpression ''
                          {
                            dev = [ pkgs.python3Packages.pytest ];
                            redis = [ pkgs.python3Packages.redis ];
                          }
                        '';
                      };
                    };
                    importsCheck = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      description = ''
                        List of Python modules to verify can be imported after installation.

                        This provides a simple smoke test to ensure the package was built correctly.
                      '';
                      example = [ "myapp" "myapp.cli" ];
                    };
                    relaxDeps = lib.mkOption {
                      type = lib.types.either lib.types.bool (lib.types.listOf lib.types.str);
                      default = [ ];
                      description = ''
                        Remove version constraints from specified dependencies.

                        Use when the package requires specific versions but works fine with versions in nixpkgs.
                        Set to true to relax all dependencies, or provide a list of dependency names.
                      '';
                      example = [ "click" "attrs" ];
                    };
                    disabledTests = lib.mkOption {
                      type = lib.types.listOf lib.types.str;
                      default = [ ];
                      description = ''
                        List of pytest test names to skip.

                        Useful for disabling flaky or network-dependent tests.
                      '';
                      example = [ "test_network" "test_integration" ];
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
                        patches = pkg.source.patches;
                        build-system = pkg.build.pythonAppBuilder.requirements.build-system;
                        dependencies = pkg.build.pythonAppBuilder.requirements.dependencies;
                        optional-dependencies = pkg.build.pythonAppBuilder.requirements.optional-dependencies;
                        pythonImportsCheck = pkg.build.pythonAppBuilder.importsCheck;
                        pythonRelaxDeps = pkg.build.pythonAppBuilder.relaxDeps;
                        disabledTests = pkg.build.pythonAppBuilder.disabledTests;
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
