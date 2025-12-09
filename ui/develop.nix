{ inputs, ... }:

{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
      devShells.ui = pkgs.mkShell {
        packages = with pkgs; [
          entr
          jq
          live-server

          elmPackages.elm
        ];

        shellHook =
          ''
            function dev-help {
              echo -e "\nWelcome to the UI development environment !"
              echo
              echo "'cd ui' first"
              echo
              echo "Start the development server:"
              echo "  dev-server"
              echo
              echo "Run 'dev-help' to see this message again."
            }

            function dev-server {
              echo "Starting development server..."
              echo

              # Check if we're in the ui directory
              if [ ! -d "src" ]; then
                echo "Error: Please run 'cd ui' first"
                return 1
              fi

              # Generate initial config and options
              echo "Generating initial config and options..."
              cat $(nix build .#_forge-config --print-out-paths) | jq > src/forge-config.json
              cat $(nix build .#_forge-options --print-out-paths) | jq > src/options.json

              # Start watchers
              echo "Starting Main.elm watcher..."
              find src/ -name "*.elm" | entr -rn elm make src/Main.elm --output=src/main.js &
              MAIN_WATCHER_PID=$!

              echo "Starting OptionsMain.elm watcher..."
              find src/ -name "*.elm" | entr -rn elm make src/OptionsMain.elm --output=src/options.js &
              OPTIONS_WATCHER_PID=$!

              echo "Starting forge-config watcher..."
              find ../forge/ ../recipes/ -name "*.nix" | entr -rn sh -c 'cat $(nix build .#_forge-config --print-out-paths) | jq > src/forge-config.json' &
              CONFIG_WATCHER_PID=$!

              echo "Starting forge-options watcher..."
              find ../forge/ -name "*.nix" | entr -rn sh -c 'cat $(nix build .#_forge-options --print-out-paths) | jq > src/options.json' &
              OPTIONS_GEN_WATCHER_PID=$!

              # Start live-server
              echo "Starting live-server..."
              live-server --host=127.0.0.1 --port=8080 --open=/index.html src/ &
              LIVE_SERVER_PID=$!

              echo
              echo "Development server is running!"
              echo "Live server: http://127.0.0.1:8080/index.html"
              echo
              echo "Press Ctrl+C to stop all watchers and the server"

              # Trap Ctrl+C to clean up all background jobs
              trap "echo 'Stopping all watchers and live-server...'; kill $LIVE_SERVER_PID $MAIN_WATCHER_PID $OPTIONS_WATCHER_PID $CONFIG_WATCHER_PID $OPTIONS_GEN_WATCHER_PID 2>/dev/null; rm -f live-server.pid; echo 'Stopped.'; return" INT

              # Wait for all background jobs
              wait
            }

            dev-help
          '';
      };
    };
}
