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

    * Deploy registry in a shell environment or in a VM (see instructions below)

    * Launch example package container with Podman
    ```
      podman run -it --tls-verify=false \
      localhost:6443/packages/hello:latest
    ```

    * Launch example application with Podman
    ```
      podman run -it --tls-verify=false \
      localhost:6443/applications/python-web-app/api:latest
    ```

    * Launch example application with Kubernetes
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

  vm = {
    enable = true;
    name = "forge-registry";
    config = {
      ports = [ "6443:6443" ];
      system = {
        # User and group
        users.users.forge-registry = {
          isSystemUser = true;
          group = "forge-registry";
          home = "/var/lib/forge-registry";
          createHome = true;
        };
        users.groups.forge-registry = { };
        nix.settings.trusted-users = [ "forge-registry" ];

        # Service
        systemd.services.forge-registry = {
          description = "Nix Forge container registry";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          path = [ pkgs.nix ];
          environment = {
            FLASK_HOST = "127.0.0.1";
            FLASK_PORT = "6444";
            GITHUB_REPO = "github:imincik/nix-forge";
            LOG_LEVEL = "INFO";
          };
          serviceConfig = {
            Type = "simple";
            ExecStart = ''
              ${pkgs.mypkgs.forge-registry.prodEnv}/bin/gunicorn \
                --bind 127.0.0.1:6444 \
                --workers 4 \
                --timeout 600 \
                --access-logfile - \
                --error-logfile - \
                --pythonpath ${pkgs.mypkgs.forge-registry.prodEnv}/${pkgs.python3.sitePackages} \
                app:app
            '';
            User = "forge-registry";
            Group = "forge-registry";
            Restart = "on-failure";
            RestartSec = "5s";
            WorkingDirectory = "/var/lib/forge-registry";
            StateDirectory = "forge-registry";
          };
        };

        # Reverse proxy
        services.nginx = {
          enable = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;
          recommendedOptimisation = true;
          recommendedGzipSettings = true;

          virtualHosts.forge-registry = {
            default = true;
            enableACME = false;
            listen = [
              {
                addr = "0.0.0.0";
                port = 6443;
              }
            ];
            locations."/" = {
              proxyPass = "http://127.0.0.1:6444";
              proxyWebsockets = true;
            };
          };
        };

        # Nix configuration
        nix.settings = {
          experimental-features = [
            "flakes"
            "nix-command"
          ];
        };
      };

      # VM configuration
      cores = 4;
      memorySize = 1024 * 8;
      diskSize = 1024 * 40;
    };
  };
}
