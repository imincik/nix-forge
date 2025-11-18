{ inputs, lib, ... }:

let
  recipeFiles = (inputs.import-tree.withLib lib).leafs ./packages;

  # This will be called from perSystem, passing { config, lib, pkgs, ... }
  callRecipes = args: map (file: import file args) recipeFiles;
in
{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }@args:

    let
      # Extend pkgs with mypkgs containing Nix Forge packages
      pkgsExtended = pkgs // {
        mypkgs = config.packages;
      };

      recipes = callRecipes (args // {
        pkgs = pkgsExtended;
      });
    in
    {
      forge.packages = recipes;
    };
}
