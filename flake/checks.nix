{
  inputs,
  config,
  lib,
  ...
}:

{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:

    let
      # Helper function to extract passthru attribute
      passthruAttr =
        attr:
        lib.filterAttrs (_: v: v != null) (
          lib.mapAttrs' (
            name: package:
            if lib.hasAttr attr package then
              lib.nameValuePair "${name}-${attr}" package.${attr}
            else
              lib.nameValuePair name null
          ) config.packages
        );

      # All output packages
      allPackages = lib.filterAttrs (n: v: !lib.hasPrefix "_forge" n) config.packages;
    in

    {
      checks = {
        inherit (config.packages) _forge-config _forge-options;
        # inherit (config.packages) _forge-ui;
      }
      // allPackages

      # All packages passthru attributes
      // (passthruAttr "image")
      // (passthruAttr "devenv")
      // (passthruAttr "test")

      # All apps passthru attributes
      // (passthruAttr "programs")
      // (passthruAttr "containers")
      // (passthruAttr "vm");
    };
}
