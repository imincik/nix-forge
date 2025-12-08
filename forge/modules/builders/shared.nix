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
      let
        # Define shared build attributes here so they can be passed via _module.args
        sharedBuildAttrs = {
          pkgSource =
            let
              gitForges = {
                # forge = fetchFunction
                github = pkgs.fetchFromGitHub;
                gitlab = pkgs.fetchFromGitLab;
              };
            in
            pkg:
            assert
              (pkg.source.git == null && pkg.source.url == null && pkg.source.path == null)
              -> throw "'source.git', 'source.url' or 'source.path' must be defined for ${pkg.name}";
            # 1. Use path if provided
            if pkg.source.path != null then
              pkg.source.path
            # 2. Use git
            else if pkg.source.git != null then
              let
                gitForge = lib.elemAt (lib.splitString ":" pkg.source.git) 0;
                gitParams = lib.splitString "/" pkg.source.git;
              in
              gitForges.${gitForge} {
                owner = lib.removePrefix "${gitForge}:" (lib.lists.elemAt gitParams 0);
                repo = lib.lists.elemAt gitParams 1;
                rev = lib.lists.elemAt gitParams 2;
                hash = pkg.source.hash;
              }
            # 3. Fallback to tarball download
            else
              pkgs.fetchurl {
                url = pkg.source.url;
                hash = pkg.source.hash;
              };

          pkgPassthru = pkg: finalPkg: {
            test = pkgs.testers.runCommand {
              name = "${pkg.name}-test";
              buildInputs = [ finalPkg ] ++ pkg.test.requirements;
              script = pkg.test.script + "\ntouch $out";
            };
            image = pkgs.dockerTools.buildImage {
              name = "${pkg.name}";
              tag = pkg.version;
              copyToRoot = [
                finalPkg
              ];
              config = {
                Entrypoint = [ "${pkgs.bashInteractive}/bin/bash" ];
              };
            };
            devenv = pkgs.mkShell {
              env.DEVENV_PACKAGE_NAME = "${pkg.name}";
              env.DEVENV_PACKAGE_SOURCE = "${finalPkg.src}";
              inputsFrom = [
                finalPkg
              ];
              packages = pkg.development.requirements;
              shellHook = pkg.development.shellHook;
            };
          };

          pkgMeta = pkg: {
            description = pkg.description;
            mainProgram = pkg.mainProgram;
          };

          debugShellHookAttr = {
            shellHook = "source ${inputs.nix-utils}/nix-develop-interactive.bash";
          };
        };
      in
      {
        options = {
          # No options needed
        };

        config = {
          # Pass shared build attributes to other modules via _module.args
          _module.args.sharedBuildAttrs = sharedBuildAttrs;
        };
      }
    );
  };
}
