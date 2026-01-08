# Nix Forge

**WARNING: this sofware is currently in alpha state of development.**

Nix Forge is lowering the barrier and learning curve required for packaging,
distributing and software deployment with Nix, enforcing best practices and
unlocking the superpowers of Nix to the ordinary humans.


## Features

* Simple, type checked configuration recipes for **packages** and
  **mutli-component applications** using
  [module system](https://nix.dev/tutorials/module-system/index.html)

* [Web UI](https://imincik.github.io/nix-forge)

* [Built-in packaging wizard](https://imincik.github.io/nix-forge/options.html)

* [LLMs support](./AGENTS.md)

* Easy [self hosting](#self-hosting)

* [Container registry](https://github.com/imincik/nix-forge-registry)


### Conceptual diagram

```mermaid
graph TB
    subgraph Sources["Sources"]
        SW1[Git Repository]
        SW2[Tarball URL]
        SW3[Local Path]
    end

    PKG[Package Recipe<br/>recipe.nix]

    subgraph PackageOutputs["Packages"]
        PO4[Nix Package]
        PO1[Development Environment]
        PO2[Shell Environment]
        PO3[Container Image]
    end

    APP[Application Recipe<br/>recipe.nix]

    subgraph AppOutputs["Applications"]
        AO1[Shell Environment<br/>CLI and GUI components]
        AO2[Container Images<br/>Services]
        AO3[NixOS VM<br/>Services]
    end

    NFR[Nix Forge Registry]

    subgraph Deployment["Deployment"]
        SHELL[Shell Environment<br/>CLI and GUI components]
        K8S[Kubernetes Cluster<br/>Services]
        NIXOS[NixOS System<br/>Services]
    end

    SW1 & SW2 & SW3 --> PKG
    PKG --> PO1 & PO2 & PO3 & PO4

    PO4 --> APP
    APP --> AO1
    APP --> AO2
    APP --> AO3

    PO3 --> NFR
    AO2 --> NFR

    AO1 --> SHELL
    AO3 --> NIXOS
    NFR --> K8S
```

## Self hosting

* Initiate new Nix Forge instance from template

```bash
nix flake init --template github:imincik/nix-forge#example
```

* Set `repositoryUrl` attribute in `flake.nix` to your repository

* Add all new files to git

* Start creating recipes  in `recipes` directory


## LLM agents

LLM agents, read [these instructions](./AGENTS.md) first.


## Commercial support

Need help with packaging software with [Nix](https://nixos.org/) or building
a NixOS system ? Get in touch with [me](https://github.com/imincik) to discuss
your project.
