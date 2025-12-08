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
  imports = [
    ./builders/shared.nix
    ./builders/plain-builder.nix
    ./builders/standard-builder.nix
    ./builders/python-app-builder.nix
  ];

  options = {
    perSystem = mkPerSystemOption (
      { config, pkgs, ... }:
      {
        options = {
          forge = {
            packagesFilter = lib.mkOption {
              internal = true;
              type = lib.types.attrsOf (lib.types.listOf lib.types.str);
              default = {
                plainBuilder = [
                  "packages.*.name"
                  "packages.*.version"
                  "packages.*.source.git"
                  "packages.*.build.plainBuilder.enable"
                  "packages.*.build.plainBuilder.requirements.native"
                  "packages.*.build.plainBuilder.requirements.build"
                  "packages.*.build.plainBuilder.configure"
                  "packages.*.build.plainBuilder.build"
                  "packages.*.build.plainBuilder.check"
                  "packages.*.build.plainBuilder.install"
                  "packages.*.test.script"
                ];
                standardBuilder = [
                  "packages.*.name"
                  "packages.*.version"
                  "packages.*.source.git"
                  "packages.*.build.standardBuilder.enable"
                  "packages.*.build.standardBuilder.requirements.native"
                  "packages.*.build.standardBuilder.requirements.build"
                  "packages.*.test.script"
                ];
                pythonAppBuilder = [
                  "packages.*.name"
                  "packages.*.version"
                  "packages.*.source.git"
                  "packages.*.build.pythonAppBuilder.enable"
                  "packages.*.build.pythonAppBuilder.requirements.build-system"
                  "packages.*.build.pythonAppBuilder.requirements.dependencies"
                  "packages.*.test.script"
                ];
              };
              description = "Defines which options are relevant for each builder type.";
            };

            packages = lib.mkOption {
              default = [ ];
              description = "List of packages.";
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    # General configuration
                    name = lib.mkOption {
                      type = lib.types.str;
                      default = "my-package";
                    };
                    description = lib.mkOption {
                      type = lib.types.str;
                      default = "";
                    };
                    version = lib.mkOption {
                      type = lib.types.str;
                      default = "1.0.0";
                    };
                    homePage = lib.mkOption {
                      type = lib.types.str;
                      default = "";
                    };
                    mainProgram = lib.mkOption {
                      type = lib.types.str;
                      default = "my-program";
                      example = "hello";
                    };

                    # Source configuration
                    source = {
                      git = lib.mkOption {
                        type = lib.types.nullOr (lib.types.strMatching "^.*:.*/.*/.*$");
                        default = null;
                        example = "github:my-user/my-repo/v1.0.0";
                      };
                      url = lib.mkOption {
                        type = lib.types.nullOr (lib.types.strMatching "^.*://.*");
                        default = null;
                        example = "https://downloads.my-project/my-package-1.0.0.tar.gz";
                      };
                      path = lib.mkOption {
                        type = lib.types.nullOr lib.types.path;
                        default = null;
                        example = lib.literalExpression "./backend/src";
                      };
                      hash = lib.mkOption {
                        type = lib.types.str;
                        default = "";
                      };
                    };

                    # Build configuration
                    build = {
                      # Builder-specific options are defined in forge/modules/builders directory

                      # Common builder options
                      extraDrvAttrs = lib.mkOption {
                        type = lib.types.attrsOf lib.types.anything;
                        default = { };
                        description = ''
                          Expert option.

                          Set extra Nix derivation attributes.
                        '';
                        example = lib.literalExpression ''
                          {
                            preConfigure = "export HOME=$(mktemp -d)"
                            postInstall = "rm $out/somefile.txt"
                          }
                        '';
                      };
                      debug = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                        description = ''
                          Enable interactive package build environment for debugging.

                          Launch environment:
                          ```
                          mkdir dev && cd dev
                          nix develop .#<package>
                          ```

                          and follow instructions.
                        '';
                      };
                    };

                    # Test configuration
                    test = {
                      requirements = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                      };
                      script = lib.mkOption {
                        type = lib.types.str;
                        default = ''
                          echo "Test script"
                        '';
                      };
                    };

                    # Development configuration
                    development = {
                      requirements = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                      };
                      shellHook = lib.mkOption {
                        type = lib.types.str;
                        default = ''
                          echo -e "\nWelcome. This environment contains all dependencies required"
                          echo "to build $DEVENV_PACKAGE_NAME from source."
                          echo
                          echo "Grab the source code from $DEVENV_PACKAGE_SOURCE"
                          echo "or from the upstream repository and you are all set to start hacking."
                        '';
                      };
                    };
                  };
                }
              );
            };
          };
        };

        # Config section is now provided by builder modules
        config = { };
      }
    );
  };
}
