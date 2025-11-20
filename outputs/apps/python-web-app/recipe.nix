{
  config,
  lib,
  pkgs,
  ...
}:

{
  name = "python-web-app";
  version = "1.0.0";
  description = "Simple web application with database backend.";
  usage = ''
    This is a simple example app which provides a web API to manage a list of
    users.

    1. Initialize database
    ```
      curl -X POST localhost:5000/init
    ```

    2. Add a new user
    ```
      curl -X POST \
        --header "Content-Type: application/json" \
        --data '{"name":"username"}' \
      localhost:5000/users
    ```

    3. Get list of all users
    ```
      curl localhost:5000/users
    ```
  '';

  programs = {
    requirements = [
      pkgs.curl
    ];
  };

  containers = {
    images = [
      {
        name = "api";
        requirements = [ pkgs.mypkgs.python-web ];
        config.CMD = [
          "python-web"
        ];
      }
    ];
    composeFile = ./compose.yaml;
  };

  vm = {
    enable = true;
    name = "database";
    config.system = {
      # database service
      services.postgresql.enable = true;
      services.postgresql.enableTCPIP = true;
      services.postgresql.authentication = ''
        local all all trust
        host all all 0.0.0.0/0 trust
        host all all ::0/0 trust
      '';
      # api service
      systemd.services.api.script = "${pkgs.mypkgs.python-web}/bin/python-web";
      systemd.services.api.wantedBy = [
        "multi-user.target"
      ];
    };
    config.ports = [
      "5000:5000"
    ];
  };
}
