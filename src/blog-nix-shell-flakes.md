
This post aims to help you getting started with Nix Flakes in order to ease the distribution of reproducible shell environments.

## What is Nix Flakes ?

In a previous [blog post about nix-shell](https://www.softwarefactory-project.io/howto-manage-shareable-reproducible-nix-environments-via-nix-shell.html) we have introduced [Nix](https://nixos.org/) and how to benefit from the `nix-shell` feature to manage shareable and reproducible shell environments.

However defining an environment using `nix-shell` lacks of standardization. The new Nix [flake](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html) standardizes the usage of Nix artifacts. The Nix project provides a new command called `nix flake` which handles `flake.nix` files.

## How to enable nix flake

To install Nix please refer to the [previous blog post](https://www.softwarefactory-project.io/howto-manage-shareable-reproducible-nix-environments-via-nix-shell.html#how-to-install-nix).

The `flake` feature is still considered experimental thus a specific Nix configuration is necessary in `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

## A Shell environment described as a Flake

Based on the [format definition for a flake](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-format) we can rewrite our [previous simple shell](https://www.softwarefactory-project.io/howto-manage-shareable-reproducible-nix-environments-via-nix-shell.html#a-simple-shell-nix-definition).

```
{
  description = "My-project build environment";
  nixConfig.bash-prompt = "[nix(my-project)] ";
  inputs = { nixpkgs.url = "github:nixos/nixpkgs/22.11"; };

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux.pkgs;
      fooScript = pkgs.writeScriptBin "foo.sh" ''
        #!/bin/sh
        echo $FOO
      '';
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        name = "My-project build environment";
        buildInputs = [
          pkgs.python39
          pkgs.python39Packages.tox
          pkgs.python39Packages.flake8
          pkgs.python39Packages.requests
          pkgs.python39Packages.ipython
          fooScript
        ];
        shellHook = ''
          echo "Welcome in $name"
          export FOO="BAR"
        '';
      };
    };
}
```

Then by running `nix develop` with enter the shell (`devShell`).
Note that, when inside a git repository, the `flake.nix` file must a be at least
staged with `git add` if not `nix` will ignore it. The `nix flake check` command
can be use to validate the flake file.

```
$ nix develop
Welcome in My-project-build-environment
[nix(my-project)] python --version
Python 3.9.15
[nix(my-project)] which ipython
/nix/store/1kgkssy7lkgsxpjii618ddjq2v03473x-python3.9-ipython-8.4.0/bin/ipython
```

A `flake.nix` file must follow a specific format based on the [Nix language](https://nixos.org/guides/nix-language.html). The base structure in an `attribute set  { ... }` with specific attributes such as:

  - description: a simple string that defines the flake's purpose.
  - inputs: an attribute set that defines the flake's dependencies.
  - outputs: a function that returns an attribute set with arbitratry attribute. However nix' subcommands expect to find specific attributes in the flake's output. For instance the `nix develop` expects to find the `devShells` attribute.

Note that we pin the `nixpkgs` version to the `22.11` tag by overiding the
nixpkgs's url in the input attribute. For better reproducibility, nix creates a
`flake.lock` file to pin dependencies to specific git hashes. This `lock` file
should be distributed along with the `flake.nix` file.

The nix flake `metadata` and `show` subcommands can be used to display flake'
dependencies and output.

A `flake` can be easily shared via a git repository. For instance the [Monocle](https://github.com/change-metrics/monocle) project provides a flake with a `devShell` output then to
get the same development environment than Monocle' developers, then simply run:

```
# Note that the first run might take long to fetch binary dependencies from the
# nix cache and to build unavailable binary dependencies (from the cache).

$ nix develop github:change-metrics/monocle
```

## A dev Shell for our new team project

Let say that our team is working on a new Python project which is a Flask application
relying on a PostgreSQL database. As a team, we agreed that will gain in productivity
if we all share the same development environment.

We want to ensure that, whatever the team member Operating System, each team member,
when hacking on the new project, uses:

 - The same Python / pip / setuptools version
 - The same code formatter version
 - The same virtual environment management version
 - The same PostgreSQL server version / configuration



## To go further

productivity
