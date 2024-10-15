.. _rebuilding_packages:

Rebuilding packages
-------------------

Each component of Software Factory is distributed via a package and as a contributor you may
need to rebuild a package. You will find most RPM package definitions in
<component>-distgit repositories and sources in <component> repositories.

Here is an example to rebuild the Zuul package.

.. code-block:: bash

 ./zuul_rpm_build.py --project scl/zuul

Newly built packages are available in the zuul-rpm-build directory.

Use the "--noclean" argument to speed the process up. This argument prevents
the mock environment from being destroyed and rebuilt, but does not clean the
zuul-rpm-build directory so you might want to clean it first.

.. code-block:: bash

 rm -Rf ./zuul-rpm-build/* && ./zuul_rpm_build.py --noclean --project scl/zuul

Multiple packages can be specified to trigger their builds.

.. code-block:: bash

 rm -Rf ./zuul-rpm-build/* && ./zuul_rpm_build.py --noclean --project scl/zuul --project scl/nodepool
