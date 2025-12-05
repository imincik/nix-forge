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
        options.forge = {
          repositoryUrl = lib.mkOption {
            type = lib.types.str;
            default = "github:imincik/nix-forge";
            description = ''
              Nix Forge repository URL.
            '';
            example = "github:imincik/nix-forge";
          };

          recipeDirs = {
            packages = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = "recipes/packages";
              description = ''
                Directory containing package recipe files.
                Each recipe should be a recipe.nix file in a subdirectory
                (e.g., recipes/packages/hello/recipe.nix).

                Set to null to disable automatic package recipe loading.
              '';
              example = "recipes/packages";
            };

            apps = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = "recipes/apps";
              description = ''
                Directory containing app recipe files.
                Each recipe should be a recipe.nix file in a subdirectory
                (e.g., recipes/apps/my-app/recipe.nix).

                Set to null to disable automatic app recipe loading.
              '';
              example = "recipes/apps";
            };
          };
        };
      }
    );
  };
}
