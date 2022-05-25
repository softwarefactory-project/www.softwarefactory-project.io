K1S is not working properly after upgrade
#########################################

:date: 2022-05-25 11:00
:category: blog
:authors: sf

The k1s hypervisor might not work properly after update Centos instance.
This process is also automatically done on upgrade Software Factory Project
to the newest release 3.7.

If the hypervisor is not working as expected, we suggest to downgrade the
podman package from package `podman-1.6.4-32` to `podman-1.6.4-29`.

To ensure, that the podman is broken, you can run a command:

.. code-block:: bash

   echo test | podman exec -i interactive-test cat

To install previous podman package version, you can execute command on k1s host:

.. code-block:: bash

   yum downgrade podman-1.6.4-29.el7_9.x86_64

The Software Factory team report that issue to the podman community, but
the patch is not released yet.

More information you can find:

- https://bugzilla.redhat.com/show_bug.cgi?id=2087994
