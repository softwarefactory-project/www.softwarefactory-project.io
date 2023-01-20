Reproducible Shell environments via Nix Flakes
##############################################

:date: 2023-01-24
:category: blog
:authors: Fabien Boucher

.. raw:: html

   <style type="text/css">

     .literal {
       border-radius: 6px;
       padding: 1px 1px;
       background-color: rgba(27,31,35,.05);
     }

   </style>

This post aims to help you getting started with Nix Flakes in order to
ease the distribution of reproducible shell environments.

.. _what-is-nix-flakes-:

What is Nix Flakes ?
====================

In a previous `blog post about nix-shell`_ we have introduced `Nix`_ and
how to benefit from the ``nix-shell`` feature to manage shareable and
reproducible shell environments.

However defining an environment using ``nix-shell`` lacks of
standardization. The new Nix `flake`_ standardizes the usage of Nix
artifacts. The Nix project provides a new command called ``nix flake``
which handles ``flake.nix`` files.

How to enable nix flake
=======================

To install Nix please refer to the `previous blog post`_.

The ``flake`` feature is still considered experimental thus a specific
Nix configuration is necessary in ``~/.config/nix/nix.conf``:

::

   experimental-features = nix-command flakes

A Shell environment described as a Flake
========================================

Based on the `format definition for a flake`_ we can rewrite our
`previous simple shell`_.

::

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

Then by running ``nix develop`` with enter the shell (``devShell``).
Note that, when inside a git repository, the ``flake.nix`` file must a
be at least staged with ``git add`` if not ``nix`` will ignore it. The
``nix flake check`` command can be use to validate the flake file.

::

   $ nix develop
   Welcome in My-project-build-environment
   [nix(my-project)] python --version
   Python 3.9.15
   [nix(my-project)] which ipython
   /nix/store/1kgkssy7lkgsxpjii618ddjq2v03473x-python3.9-ipython-8.4.0/bin/ipython

A ``flake.nix`` file must follow a specific format based on the `Nix
language`_. The base structure in an ``attribute set  { ... }`` with
specific attributes such as:

-  description: a simple string that defines the flake's purpose.
-  inputs: an attribute set that defines the flake's dependencies.
-  outputs: a function that returns an attribute set with arbitratry
   attribute. However nix' subcommands expect to find specific
   attributes in the flake's output. For instance the ``nix develop``
   expects to find the ``devShells`` attribute.

Note that we pin the ``nixpkgs`` version to the ``22.11`` tag by
overiding the nixpkgs's url in the input attribute. For better
reproducibility, nix creates a ``flake.lock`` file to pin dependencies
to specific git hashes. This ``lock`` file should be distributed along
with the ``flake.nix`` file.

The nix flake ``metadata`` and ``show`` subcommands can be used to
display flake' dependencies and output.

A ``flake`` can be easily shared via a git repository. For instance the
`Monocle`_ project provides a flake with a ``devShell`` output then to
get the same development environment than Monocle' developers, then
simply run:

::

   # Note that the first run might take long to fetch binary dependencies from the
   # nix cache and to build unavailable binary dependencies (from the cache).

   $ nix develop github:change-metrics/monocle

A flake to build the Software Factory website
=============================================

Our website requires some dependencies available on the system in order
to be built. To ensure that each teams' member can build the website
locally, without spending time understanding which dependencies are
needed and then struggling with versions/incompatibility issues, we can
provide a ``flake``.

Here is the ``flake`` we use:

::

   {
     description = "sf.io site builder flake";
     inputs = { nixpkgs.url = "github:nixos/nixpkgs/22.11"; };

     outputs = { self, nixpkgs }:
       let
         pkgs = nixpkgs.legacyPackages.x86_64-linux.pkgs;
         buildScript = pkgs.writeScriptBin "build-site.sh" ''
           #!/bin/sh

           pushd src
           ./blog-htmx.sh
           ./blog-practical-haskell-use-cases.sh
           ./blog-introducing-effects.sh
           ./blog-introducing-functional-programming-to-pythonistas.sh
           ./blog-sf-resources-in-reason.sh
           ./blog-nix-shell.sh
           ./blog-nix-shell-flakes.sh
           popd

           pushd website
           pelican content -o output
           popd
         '';
       in {
         devShells.x86_64-linux.default = pkgs.mkShell {
           name = "Website toolings shell";
           buildInputs = [ pkgs.pandoc pkgs.python39Packages.pelican buildScript ];
           shellHook = ''
             echo "Welcome in the nix shell for $name"
             echo "Run the build-site.sh command to build the website in website/output"
             echo "Then run: firefox website/output/index.html"
           '';
         };
       };
   }

If a specific package version is needed in the shell, then it is
possible to override a package' attributes to make a new derivation. For
instance, let's say we need for some reasons to stick to ``pelican``
version 4.7.2 instead of 4.8.0 version provided in ``nixpkgs`` 22.11.
Then, we can override the `current definition`_ in our ``flake.nix``
using the ``overridePythonAttrs`` this way:

::

   let pelican = pkgs.python39Packages.pelican.overridePythonAttrs (old: rec {
     version = "4.7.2";
     src = pkgs.fetchFromGitHub {
       owner = "getpelican";
       repo = old.pname;
       rev = "refs/tags/${version}";
       hash = "sha256-ZBGzsyCtFt5uj9mpOpGdTzGJET0iwOAgDTy80P6anRU=";
       postFetch = ''
         rm -r $out/pelican/tests/output/custom_locale/posts
       '';
     };
   });

and finally use the new ``pelican`` derivation in the ``buildInputs`` of
the ``mkShell``' attributes.

Note that you might need to set ``hash`` to an empty string to force Nix
to provide you the new hash to be set in the override.

.. _blog post about nix-shell: https://www.softwarefactory-project.io/howto-manage-shareable-reproducible-nix-environments-via-nix-shell.html
.. _Nix: https://nixos.org/
.. _flake: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html
.. _previous blog post: https://www.softwarefactory-project.io/howto-manage-shareable-reproducible-nix-environments-via-nix-shell.html#how-to-install-nix
.. _format definition for a flake: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-format
.. _previous simple shell: https://www.softwarefactory-project.io/howto-manage-shareable-reproducible-nix-environments-via-nix-shell.html#a-simple-shell-nix-definition
.. _Nix language: https://nixos.org/guides/nix-language.html
.. _Monocle: https://github.com/change-metrics/monocle
.. _current definition: https://github.com/NixOS/nixpkgs/blob/22.11/pkgs/development/python-modules/pelican/default.nix
