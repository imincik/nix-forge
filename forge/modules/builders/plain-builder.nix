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
                  build.plainBuilder = {
                    enable = lib.mkEnableOption ''
                      Plain builder.
                    '';
                    requirements = {
                      native = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                      };
                      build = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                      };
                    };
                    configure = lib.mkOption {
                      type = lib.types.str;
                      default = "echo 'Configure phase'";
                    };
                    build = lib.mkOption {
                      type = lib.types.str;
                      default = "echo 'Build phase'";
                    };
                    check = lib.mkOption {
                      type = lib.types.str;
                      default = "echo 'Check phase'";
                    };
                    install = lib.mkOption {
                      type = lib.types.str;
                      default = "echo 'Install phase'";
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

              plainBuilderPkgs = lib.listToAttrs (
                map (pkg: {
                  name = pkg.name;
                  value = pkgs.callPackage (
                    # Derivation start
                    { stdenv }:
                    stdenv.mkDerivation (
                      finalAttrs: {
                        pname = pkg.name;
                        version = pkg.version;
                        src = sharedBuildAttrs.pkgSource pkg;
                        nativeBuildInputs = pkg.build.plainBuilder.requirements.native;
                        buildInputs = pkg.build.plainBuilder.requirements.build;
                        configurePhase = pkg.build.plainBuilder.configure;
                        buildPhase = pkg.build.plainBuilder.build;
                        installPhase = pkg.build.plainBuilder.install;
                        checkPhase = pkg.build.plainBuilder.check;
                        doCheck = true;
                        doInstallCheck = true;
                        passthru = sharedBuildAttrs.pkgPassthru pkg finalAttrs.finalPackage;
                        meta = sharedBuildAttrs.pkgMeta pkg;
                      }
                      // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
                    )
                    # Derivation end
                  ) { };
                }) (lib.filter (p: p.build.plainBuilder.enable == true) cfg)
              );
            in
            plainBuilderPkgs;
        };
      }
    );
  };
}
