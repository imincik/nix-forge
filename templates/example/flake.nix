{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-forge.url = "github:imincik/nix-forge";
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
              packages = ./recipes/packages;
              apps = ./recipes/apps;
            };
          };
        };
    };
}
