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
              description = ''
                Defines which configuration options are relevant for each builder type.

                Used for filtering options documentation to show only builder-specific
                options in the generated documentation.
              '';
            };

            packages = lib.mkOption {
              default = [ ];
              description = ''
                List of packages to include in forge.

                Each package uses one of the available builders.
                Only one builder can be enabled per package by setting build.<builder>.enable = true.
              '';
              type = lib.types.listOf (
                lib.types.submodule {
                  options = {
                    # General configuration
                    name = lib.mkOption {
                      type = lib.types.str;
                      default = "my-package";
                      description = "Package name.";
                      example = "hello";
                    };
                    description = lib.mkOption {
                      type = lib.types.str;
                      default = "";
                      description = "Package description.";
                      example = "A program that prints greeting messages";
                    };
                    version = lib.mkOption {
                      type = lib.types.str;
                      default = "1.0.0";
                      description = "Package version.";
                      example = "2.12.1";
                    };
                    homePage = lib.mkOption {
                      type = lib.types.str;
                      default = "";
                      description = "Package home page URL.";
                      example = "https://www.gnu.org/software/hello/hello-2.12.1.tar.gz";
                    };
                    mainProgram = lib.mkOption {
                      type = lib.types.str;
                      default = "my-program";
                      description = "Name of the main executable program.";
                      example = "hello";
                    };

                    # Source configuration
                    source = {
                      git = lib.mkOption {
                        type = lib.types.nullOr (lib.types.strMatching "^.*:.*/.*/.*$");
                        default = null;
                        description = ''
                          Git repository URL with revision.

                          Format: platform:owner/repo/revision
                        '';
                        example = "github:my-user/my-repo/v1.0.0";
                      };
                      url = lib.mkOption {
                        type = lib.types.nullOr (lib.types.strMatching "^.*://.*");
                        default = null;
                        description = "Source tarball URL.";
                        example = "https://downloads.my-project/my-package-1.0.0.tar.gz";
                      };
                      path = lib.mkOption {
                        type = lib.types.nullOr lib.types.path;
                        default = null;
                        description = "Relative path to local source code directory.";
                        example = lib.literalExpression "./backend/src";
                      };
                      hash = lib.mkOption {
                        type = lib.types.str;
                        default = "";
                        description = ''
                          Source code hash.

                          Use empty string to get the hash during a first build.
                        '';
                        example = "sha256-jZkUKv2SV28wsM18tCqNxoCZmLxdYH2Idh9RLibH2yA=";
                      };
                    };

                    # Build configuration
                    build = {
                      # Builder-specific options (plainBuilder, standardBuilder, pythonAppBuilder)
                      # are defined in separate modular files in forge/modules/builders/ directory.
                      # Each builder module defines its own options and configuration logic.

                      # Common builder options (available to all builders)
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
                        description = "Additional packages required for running tests.";
                        example = lib.literalExpression "[ pkgs.curl pkgs.jq ]";
                      };
                      script = lib.mkOption {
                        type = lib.types.str;
                        default = ''
                          echo "Test script"
                        '';
                        description = ''
                          Bash script to run package tests.

                          The package being tested is available in PATH.
                          Run with: nix build .#<package>.test
                        '';
                        example = lib.literalExpression ''
                          '''
                          hello | grep "Hello, world"
                          '''
                        '';
                      };
                    };

                    # Development configuration
                    development = {
                      requirements = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                        description = ''
                          Additional packages to include in the development environment.

                          All build requirements are automatically included.
                        '';
                        example = lib.literalExpression "[ pkgs.git pkgs.vim ]";
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
                        description = ''
                          Bash script to run when entering the development environment.

                          Enter with: nix develop .#<package>
                        '';
                        example = lib.literalExpression ''
                          '''
                          echo "Welcome to my-package development environment!"
                          echo "Run 'make' to build the project"
                          '''
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
