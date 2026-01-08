# Nix Forge

**WARNING: this sofware is currently in alpha state of development.**

Nix Forge is an attempt to lower the barrier and learning curve required for
packaging and deploying software with Nix, enforce best practices and unlock the
superpowers of Nix.


## Features

* Simple, type checked configuration recipes for **packages** and
  **mutli-component applications** using
  [module system](https://nix.dev/tutorials/module-system/index.html)

* [Web UI](https://imincik.github.io/nix-forge)

* [Recipe builder](https://imincik.github.io/nix-forge/options.html)

* Easy [self hosting](#self-hosting)

* [LLM support](./AGENTS.md)

### Packages outputs

* Shell environments
* Container images
* Development environments

### Multi-component applications outputs

* Shell environments (for CLI and GUI components)
* Container images (for services)
* NixOS systems (for services)


## Packaging workflow

1. Create a new package recipe file in
   `recipes/packages/<package>/recipe.nix` and add it to git.

1. Build package

```bash
nix build .#<package> -L
```

1. Inspect and test build output in `./result` directory

1. Submit PR and wait for tests

1. Publish package by merging the PR

### Examples

* [Package recipe examples](recipes/packages)

* [Application recipe examples](recipes/apps)

### Debugging

Set `build.debug = true` and launch interactive package build
environment by running

```bash
mkdir dev && cd dev
nix develop .#<package>
```

and follow instructions.

### Tests

* Run package test

```bash
nix build .#<package>.test -L
```


## Self hosting

* Initiate new Nix Forge instance from template

```bash
nix flake init --template github:imincik/nix-forge#example
```

* Set `repositoryUrl` attribute in `flake.nix` to your repository

* Add all new files to git

* Create recipes  in `recipes` directory


## LLM agents

LLM agents, read [these instructions](./AGENTS.md) first.


## TODOs

* CI checks and workflows (dependencies updates, ...)

* Many more language speciffic builders and configuration options
