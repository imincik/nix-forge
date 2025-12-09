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
    enable = true;
    requirements = [
      pkgs.mypkgs.hello-nix
    ];
  };

  containers = {
    enable = true;
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
