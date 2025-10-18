{ inputs, flake-parts-lib, ... }:

{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      optionsDoc =
        modules:
        let
          eval = lib.evalModules {
            modules = modules;
            specialArgs = { inherit flake-parts-lib; };
          };
          doc = pkgs.nixosOptionsDoc {
            warningsAreErrors = false;
            options = lib.removeAttrs eval.options [ "_module" ];
            transformOptions =
              opt:
              (
                opt
                // {
                  name = lib.removePrefix "perSystem.forge." opt.name;
                  declarations = [ ];
                }
              );
          };
          options = pkgs.runCommand "options.json" { } ''
            cp ${doc.optionsJSON}/share/doc/nixos/options.json $out
          '';
        in
        options;
    in

    {
      packages = {
        _forge-config = pkgs.writeTextFile {
          name = "forge-config.json";
          text = builtins.toJSON config.forge;
        };

        _forge-options = optionsDoc [
          ./modules/apps.nix
          ./modules/packages.nix
        ];

        _forge-ui = pkgs.callPackage ../ui/package.nix {
          inherit (config.packages) _forge-config _forge-options;
        };
      };
    };
}
