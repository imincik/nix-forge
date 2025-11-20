{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "forge-registry-app";
  version = "0.1.0";
  description = "OCI-compliant container registry for Nix Forge.";
  usage = ''
    This service allows to load Nix Forge containers directly to Docker, Podman
    or Kubernetes.

    1. Deploy registry in a VM (see instructions below)

    2. Run example package container with Podman
    ```
      podman run -it --tls-verify=false \
      localhost:6443/packages/hello:latest
    ```

    3. Run example application with Podman
    ```
      podman run -it --tls-verify=false \
      localhost:6443/applications/python-web-app/api:latest
    ```

    4. Run example application with Kubernetes
    ```
      kubectl run python-web --insecure-skip-tls-verify \
      --image=localhost:6443/applications/python-web-app/api:latest
    ```
  '';

  programs = {
    requirements = [
      pkgs.mypkgs.forge-registry
    ];
  };

  containers = {
    # FIXME: requires nix to run in container
    images = [
      {
        name = "forge-registry";
        requirements = [
          pkgs.mypkgs.forge-registry
          pkgs.nix
        ];
        config.CMD = [ "forge-registry" ];
      }
    ];
    composeFile = ./compose.yaml;
  };

  vm = {
    enable = true;
    name = "forge-registry";
    requirements = [
      pkgs.mypkgs.forge-registry
      pkgs.nix
    ];
    config = {
      ports = [ "6443:6443" ];
      system = {
        systemd.services.forge-registry = {
          description = "Nix Forge container registry";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          environment = {
            FLASK_HOST = "0.0.0.0";
            FLASK_PORT = "6443";
            GITHUB_REPO = "github:imincik/nix-forge";
            LOG_LEVEL = "INFO";
          };
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.mypkgs.forge-registry}/bin/forge-registry";
            Restart = "on-failure";
            RestartSec = "5s";
          };
          path = [ pkgs.nix ];
        };
        nix.settings = {
          trusted-users = [
            "root"
            "@wheel"
            "@trusted"
          ];
          experimental-features = [
            "flakes"
            "nix-command"
          ];
        };
      };
      memorySize = 1024 * 4;
      diskSize = 1024 * 10;
    };
  };
}
