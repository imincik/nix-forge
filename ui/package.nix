{
  buildElmApplication,
  symlinkJoin,

  _forge-config,
  _forge-options,
}:

let
  main = buildElmApplication {
    pname = "forge-ui-elm";
    version = "0.1.0";
    src = ./.;
    elmLock = ./elm.lock;
    entry = [ "src/Main.elm" ];
    output = "main.js";
    doMinification = true;
    enableOptimizations = true;
  };

  options = buildElmApplication {
    pname = "forge-ui-options";
    version = "0.1.0";
    src = ./.;
    elmLock = ./elm.lock;
    entry = [ "src/OptionsMain.elm" ];
    output = "options.js";
    doMinification = true;
    enableOptimizations = true;
  };

  agentsFile = ../AGENTS.md;
in
symlinkJoin {
  name = "forge-ui";
  paths = [
    main
    options
  ];
  postBuild = ''
    # Copy static files
    cp ${./src/index.html} $out/index.html
    cp ${./src/options.html} $out/options.html
    cp -r ${./src/resources} $out/resources
    cp ${agentsFile} $out/AGENTS.md

    # Symlink config files
    ln -s ${_forge-config} $out/forge-config.json
    ln -s ${_forge-options} $out/options.json

    # Rename minimized Elm outputs
    mv $out/main.min.js $out/main.js
    mv $out/options.min.js $out/options.js
  '';
}
