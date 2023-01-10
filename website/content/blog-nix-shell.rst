Howto benefit Nix via nix-shell
###############################

:date: 2023-01-09
:category: blog
:authors: Fabien

.. raw:: html

   <style type="text/css">

     .literal {
       border-radius: 6px;
       padding: 1px 1px;
       background-color: rgba(27,31,35,.05);
     }

   </style>

This post aims to teach how to leverage nix via the nix-shell feature in
order to ease the distribution of reproducible environment.

.. _what-is-nix-:

What is Nix ?
=============

`Nix`_ is a purely functional package manager. It manages packages
independently from your system by maintaining a package store in
``/nix/store``. This makes Nix convenient because various softwares and
libraries can be installed without the fear of breaking the base system
provided by your Linux distribution, nor having to handle potential
conflicts in the versions of dependencies. Furthermore, as the Nix store
is a graph of cryptographic hashes of package’s build dependencies, then
it brings the guarantee reproducible environments.

How to install nix
==================

This page describes `installation instructions`_.

We'll use the single user installation process (the user needs to be
able to ``sudo -i``):

::

   sh <(curl -L https://nixos.org/nix/install) --no-daemon
   . ~/.nix-profile/etc/profile.d/nix.sh

Now let's verify our nix installation is working as expected:

::

   nix --version
   nix (Nix) 2.12.0

Using the nix-shell to setup an environment
===========================================

A Nix shell environment gives access to specified packages.

For instance, this command enhances the current shell environment to
make ``cowsay`` and ``fortune`` available in the PATH:

::

   $ nix-shell -p cowsay fortune
   these 3 paths will be fetched (1.76 MiB download, 6.34 MiB unpacked):
     /nix/store/4agvv4d3jl9lcwxd46qjlkzcibsbryvz-recode-3.7.9
     /nix/store/fkrh0bzwymq0220fscz7grd3yrh5hzsd-cowsay-3.04
     /nix/store/k5dfq7qj0vp10jyb2pn780f323f4vdzm-fortune-mod-3.6.1
   copying path '/nix/store/fkrh0bzwymq0220fscz7grd3yrh5hzsd-cowsay-3.04' from 'https://cache.nixos.org'...
   copying path '/nix/store/4agvv4d3jl9lcwxd46qjlkzcibsbryvz-recode-3.7.9' from 'https://cache.nixos.org'...
   copying path '/nix/store/k5dfq7qj0vp10jyb2pn780f323f4vdzm-fortune-mod-3.6.1' from 'https://cache.nixos.org'...

   $ type cowsay fortune
   cowsay is hashed (/nix/store/fkrh0bzwymq0220fscz7grd3yrh5hzsd-cowsay-3.04/bin/cowsay)
   fortune is hashed (/nix/store/k5dfq7qj0vp10jyb2pn780f323f4vdzm-fortune-mod-3.6.1/bin/fortune)

The Nix project maintains a binary cache then packages are usually just
downloaded from the cache.

However this command does not guarantee the same versions of packages
will be installed when the same command runs on another machine. Indeed
package definitions are maintained in the `nixpkgs`_ project, and to
ensure reproducibility the version of nixpkgs must be pinned.

By default, running ``nix-shell``, uses the default nixpkgs channel,
which might be set to a different version across nix installations.

::

   $ nix-instantiate --eval -E '(import <nixpkgs> {}).lib.version'
   "23.05pre440754.0c9aadc8eff"

The ``nix-shell`` command can be run with a pinned version of nixpkgs,
by doing so we get the guarantee run a reproducible shell environment:

::

   $ nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/tags/22.11.tar.gz -p cowsay

Now let use our new knowledge to get a Python 3.9 shell with various
Python libraries and ipython:

::

   $ nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/tags/22.11.tar.gz -p \
   python39 python39Packages.tox python39Packages.flake8 python39Packages.requests \
   python39Packages.ipython

   $ type python tox flake8 ipython
   python is /nix/store/h4h5rxs0hzpzvz37yrwv1k2na1acgzww-python3-3.9.15/bin/python
   tox is hashed (/nix/store/0iifww8anqsg84apj0dklrpiqjwn1nzy-python3.9-tox-3.27.1/bin/tox)
   flake8 is hashed (/nix/store/mri6xdgqa5b4hj7by88mlidksi1h7kd2-python3.9-flake8-5.0.4/bin/flake8)
   ipython is /nix/store/1kgkssy7lkgsxpjii618ddjq2v03473x-python3.9-ipython-8.4.0/bin/ipython

   $ python --version && flake8 --version && tox --version && ipython --version
   Python 3.9.15
   5.0.4 (mccabe: 0.7.0, pycodestyle: 2.9.1, pyflakes: 2.5.0) CPython 3.9.15 on Linux
   3.27.1 imported from /nix/store/0iifww8anqsg84apj0dklrpiqjwn1nzy-python3.9-tox-3.27.1/lib/python3.9/site-packages/tox/__init__.py
   8.4.0

   $ exit

   # Note that running again the nix-shell command will enter the shell instantanously as all
   # binaries have been fetched into /nix/store already.

If you try the same commands as above on your machine you should see the
extact same output.

Currently, nixpkgs owns definitions for around 80,000 packages. You can
search for available packages on `search.nixos.org`_.

.. _a-simple-shellnix-definition:

A simple shell.nix definition
=============================

The ``nix-shell`` command looks for a ``shell.nix`` file in the current
directory and if it exists the shell environment is loaded. This is
handy in order to share with co-workers a common and reproducible work
environment for a given project. Since it is a pure text file, it can
also be easily versioned with git.

As the most simple example of ``shell.nix`` to deploy the previous
Python environment:

::

   { pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/tags/22.11.tar.gz") {} }:

   let fooScript = pkgs.writeScriptBin "foo.sh" ''
     #!/bin/sh
     echo $FOO
   '';

   in pkgs.mkShell {
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
   }

This ``shell.nix`` sample describes a shell with:

-  Some Python packages available
-  A script ``foo.sh`` available in the PATH
-  Some commands (via ``shellHook`` to run a shell startup)

Enter the shell by typing: ``nix-shell``.

To go further
=============

In this post we learned the basic steps to bootstrap a simple shell
environment with Nix. However more complex and reproducible environment
setups can be built via a Nix shell, like the setup of services
(MariaDB, Zookeeper, ...), installation of additional scripts,
compilation/installation of softwares and libraries not available in
nixpkgs, but this goes beyond that simple introdution.

Here are some interesting resources to `continue your learning`_.

.. _Nix: https://nixos.org
.. _installation instructions: https://nixos.org/download.html#download-nix
.. _nixpkgs: https://github.com/NixOS/nixpkgs
.. _search.nixos.org: https://search.nixos.org
.. _continue your learning: https://nix.dev/recommended-reading
