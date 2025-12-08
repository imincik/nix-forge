{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "hello-app";
  version = "1.0.0";
  description = "Say hello to Nix.";

  programs = {
    requirements = [
      pkgs.mypkgs.hello-nix
    ];
  };

  containers = {
    images = [
      {
        name = "hello";
        requirements = [ pkgs.mypkgs.hello-nix ];
        config.CMD = [
          "hello"
        ];
      }
    ];
    composeFile = ./compose.yaml;
  };

  vm = {
    enable = true;
    name = "hello";
    requirements = [
      pkgs.mypkgs.hello-nix
    ];
  };
}
