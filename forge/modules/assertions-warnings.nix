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
      { config, pkgs, ... }:
      {
        options = {
          assertions = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            condition = lib.mkOption {
              type = lib.types.bool;
              description = "Condition that must be true for the assertion to pass.";
            };
            message = lib.mkOption {
              type = lib.types.str;
              description = "Error message to show when assertion fails.";
            };
          };
        }
      );
      internal = true;
      default = [ ];
      description = ''
        Configuration assertions.

        This option allows modules to express conditions that must hold for
        the configuration to be valid. Failed assertions (where condition = false)
        are collected and shown as errors during evaluation.
      '';
      example = lib.literalExpression ''
        [
          {
            condition = config.forge.packages != [ ];
            message = "At least one package must be defined.";
          }
        ]
      '';
    };

    warnings = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            condition = lib.mkOption {
              type = lib.types.bool;
              description = "Condition that triggers the warning when true.";
            };
            message = lib.mkOption {
              type = lib.types.str;
              description = "Warning message to show.";
            };
          };
        }
      );
      internal = true;
      default = [ ];
      description = ''
        Configuration warnings.

        This option allows modules to show warning messages during evaluation
        without failing the build. Warnings are shown when condition = true.
        Useful for deprecation notices or configuration suggestions.
      '';
      example = lib.literalExpression ''
        [
          {
            condition = pkg.source.hash == "";
            message = "Package 'foo': Consider setting source.hash.";
          }
        ]
      '';
    };
        };

        config = { };
      }
    );
  };
}
