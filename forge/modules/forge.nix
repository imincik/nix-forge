{
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
        options.forge.recipeDirs = {
          packages = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = ''
              Directory containing package recipe files.
              Each recipe should be a recipe.nix file in a subdirectory
              (e.g., outputs/packages/hello/recipe.nix).

              Set to null to disable automatic package recipe loading.
            '';
            example = lib.literalExpression "./outputs/packages";
          };

          apps = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = ''
              Directory containing app recipe files.
              Each recipe should be a recipe.nix file in a subdirectory
              (e.g., outputs/apps/my-app/recipe.nix).

              Set to null to disable automatic app recipe loading.
            '';
            example = lib.literalExpression "./outputs/apps";
          };
        };
      }
    );
  };
}
