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
    This service provides a OCI-compliant container registry for Nix Forge
    and allows to load Nix Forge containers directly to Docker, Podman or
    Kubernetes.

    1. Deploy registry in a shell environment (see instructions below)
       and launch it
    ```
      forge-registry
    ```

    2. Launch example package container with Podman
    ```
      podman run -it --tls-verify=false \
      localhost:6443/packages/hello:latest
    ```

    3. Launch example application with Podman
    ```
      podman run -it --tls-verify=false \
      localhost:6443/applications/python-web-app/api:latest
    ```

    4. Launch example application with Kubernetes
    ```
      kubectl run python-web \
      --image=localhost:6443/applications/python-web-app/api:latest
    ```
  '';

  programs = {
    enable = true;
    requirements = [
      pkgs.mypkgs.forge-registry
    ];
  };

  # TODO: enable container (requires nix to run in a container)
  # containers = {
  #   images = [
  #     {
  #       name = "forge-registry";
  #       requirements = [
  #         pkgs.mypkgs.forge-registry
  #         pkgs.nix
  #       ];
  #       config.CMD = [ "forge-registry" ];
  #     }
  #   ];
  #   composeFile = ./compose.yaml;
  # };

  # TODO: enable VM
  # vm = {
  #   enable = true;
  #   name = "forge-registry";
  #   requirements = [
  #     pkgs.mypkgs.forge-registry
  #     pkgs.nix
  #   ];
  #   config = {
  #     ports = [ "6443:6443" ];
  #     system = {
  #       systemd.services.forge-registry = {
  #         description = "Nix Forge container registry";
  #         wantedBy = [ "multi-user.target" ];
  #         after = [ "network.target" ];
  #         environment = {
  #           FLASK_HOST = "0.0.0.0";
  #           FLASK_PORT = "6443";
  #           GITHUB_REPO = "github:imincik/nix-forge";
  #           LOG_LEVEL = "INFO";
  #         };
  #         serviceConfig = {
  #           Type = "simple";
  #           ExecStart = "${pkgs.mypkgs.forge-registry}/bin/forge-registry";
  #           Restart = "on-failure";
  #           RestartSec = "5s";
  #         };
  #         path = [ pkgs.nix ];
  #       };
  #       nix.settings = {
  #         trusted-users = [
  #           "root"
  #           "@wheel"
  #           "@trusted"
  #         ];
  #         experimental-features = [
  #           "flakes"
  #           "nix-command"
  #         ];
  #       };
  #     };
  #     memorySize = 1024 * 4;
  #     diskSize = 1024 * 10;
  #   };
  # };
}
