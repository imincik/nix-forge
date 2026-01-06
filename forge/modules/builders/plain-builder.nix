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
                      Plain builder for custom build processes.

                      Use when standard builders don't fit your needs'';
                    requirements = {
                      native = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                        description = ''
                          Build-time dependencies (native architecture).

                          Tools needed during compilation that run on the build machine.
                        '';
                        example = lib.literalExpression "[ pkgs.cmake pkgs.pkg-config ]";
                      };
                      build = lib.mkOption {
                        type = lib.types.listOf lib.types.package;
                        default = [ ];
                        description = ''
                          Runtime dependencies (target architecture).

                          Libraries needed by the package at runtime.
                        '';
                        example = lib.literalExpression "[ pkgs.openssl pkgs.zlib ]";
                      };
                    };
                    configure = lib.mkOption {
                      type = lib.types.str;
                      default = "echo 'Configure phase'";
                      description = ''
                        Bash script for the configure phase.

                        Set up the build environment and generate build files.
                      '';
                      example = ''
                        mkdir build && cd build
                        cmake -DCMAKE_INSTALL_PREFIX=$out ..
                      '';
                    };
                    build = lib.mkOption {
                      type = lib.types.str;
                      default = "echo 'Build phase'";
                      description = ''
                        Bash script for the build phase.

                        Compile the source code.
                      '';
                      example = ''
                        make -j $NIX_BUILD_CORES
                      '';
                    };
                    check = lib.mkOption {
                      type = lib.types.str;
                      default = "echo 'Check phase'";
                      description = ''
                        Bash script for the check phase.

                        Run build-time tests to verify the build.
                      '';
                      example = ''
                        make test
                      '';
                    };
                    install = lib.mkOption {
                      type = lib.types.str;
                      default = "echo 'Install phase'";
                      description = ''
                        Bash script for the install phase.

                        Install files to $out.
                      '';
                      example = ''
                        make install
                      '';
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
                        patches = pkg.source.patches;
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
