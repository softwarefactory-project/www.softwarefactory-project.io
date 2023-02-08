Hacking Zuul for developers - Running unit tests
################################################

:date: 2023-02-10
:category: blog
:authors: mhuin

This article is a followup on my previous post about `Hacking Zuul for developers`_ .
Here I will explain how to set up an environment where you can run Zuul's unit tests suite.

Requirements
------------

The simplest way to set up this environment is to use a VM running Ubuntu 22.04 Server LTS, 
which is also the environment on which tests are run in Zuul's upstream CI.

I will assume you have a way to spawn one such system, whether as a VM or something else,
and that you have it configured in a way that you can SSH into it, and become root on it.

I strongly advise you to deploy the "beefiest" server you can, with the amount of CPUs being
the most impactful parameter in terms of performances. As a point of reference, I am using
a VM with 8GB of RAM and 4 vCPUs, and I run the full test suite in slightly over 2 hours.

Install basic tools
-------------------

We're going to need a few things like git, pip and docker-compose to get everything up and running.

.. code:: bash

  sudo apt -y install git python3-pip docker docker-compose

Once we have pip, we'll use it to install `bindep <https://docs.opendev.org/opendev/bindep/latest/>`_
to figure out which dependencies are needed to run the tests, and `nox <https://nox.thea.codes/en/stable/>`_ 
to actually run the test suite.

.. code:: bash

  sudo pip install nox bindep

Note that I am setting up a VM so I am not too worried about messing up with the OS, but you might want
to install these in user space rather than as root.

Fetch the zuul repo and install test dependencies
-------------------------------------------------

If you don't have a copy of the repository somewhere already, let's fetch the source code:

.. code:: bash

  git clone --depth 1 https://opendev.org/zuul/zuul && cd zuul

Bindep will next tell us what else we need to install:

.. code:: bash

  sudo apt -y install $(bindep --brief test)

At this point bindep should install two database services: mysql and postgresql. We are going to
set these up via containers, so we need to remove the packages. We do however want to make sure the DB clients
are still installed.

.. code:: bash

  sudo apt -y remove mysql-server postgresql
  sudo apt -y install postgresql-client mysql-client
  sudo apt -y autoremove

Start external services
-----------------------

Zuul requires a database backend and a `Zookeeper <https://zookeeper.apache.org/>`_ instance to be available,
even when running the unit tests suite. Luckily for us, Zuul's developers team created a very handy script
to deploy these services via a docker compose. Assuming you are still in the zuul directory:

.. code:: bash

  ROOTCMD=sudo tools/test-setup-docker.sh

Once the script terminates, you should have two databases, certificates for Zookeeper and Zookeeper itself
up and running, with parameters that can be used by the test suite. You can check the compose status with
`docker ps` or check logs with `docker-compose logs -f`.

If you are using a VM, it might be good to snapshot it now so you can easily get back to this state
whenever you want to run tests. Note that binary dependencies might change in the future so it might
be necessary to re-run bindep to keep up to date.

Running the test suite
----------------------

Before anything else, we must ensure we can use as many file descriptors as we can, because the Zookeeper
connections require a lot of them.

.. code:: bash

  ulimit -n $(ulimit -Hn)

Once again, I am running a VM so I am not worried about breaking stuff, but you might want instead to
use a lower value than the hard limit provided by `ulimit -Hn`. What's for sure is that the default value,
1024, is ridiculously low and needs to be increased.

Also, note that this command will set the limit only for the current user session; don't forget to set it
again as needed.

Assuming we are still in the zuul directory, we can list the different testing sessions configured for nox:

.. code:: bash

  nox -l

Let's do a dry run that will install python libraries requirements, but not run the actual tests:

.. code:: bash

  nox -s tests --install-only

This also will compile the React GUI application, which might take some time.

We could have run the tests directly. But with this dry run, we can now install our own dependencies
like Zuul would with a Depends-On keyword in the commit message - except we do it manually.

.. code:: bash

  source .nox/tests/bin/activate
  cd path/to/your/dependency
  python setup.py install # or whatever you use to install the dependency

To run the test suite with the modified virtualenv, use:

.. code:: bash

  nox -R -s tests

Drop the `-R` argument to recreate the virtualenv.

Given that the test suite is pretty extensive, you may want to limit your run to a few tests at a time.
You can filter out which tests to run by matching a specific regex like
`explained in the stestr documentation <https://stestr.readthedocs.io/en/stable/MANUAL.html#test-selection>`_ .

Conclusion
----------

This article presented a way to set up an environment where you can run Zuul's unit tests suite.
I have compiled all the commands used here in a script in a `gist <https://gist.github.com/mhuin/1177dc30971112404fd7c078651682ed>`_, if you want to automate things.
