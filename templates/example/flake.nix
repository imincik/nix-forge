{
  description = "Nix Forge";

  nixConfig = {
    extra-substituters = [ "https://flake-forge.cachix.org" ];
    extra-trusted-public-keys = [
      "flake-forge.cachix.org-1:cu8to1JK8J70jntSwC0Z2Uzu6DpwgcWTS3xiiye3Lyw="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-forge.url = "github:imincik/nix-forge";
    elm2nix = {
      url = "github:dwayne/elm2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-utils = {
      url = "github:imincik/nix-utils";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, nix-forge, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ nix-forge.flakeModules.default ];

      perSystem =
        { ... }:
        {
          forge = {
            repositoryUrl = "github:me/my-forge";
            recipeDirs = {
              packages = "recipes/packages";
              apps = "recipes/apps";
            };
          };
        };
    };
}
