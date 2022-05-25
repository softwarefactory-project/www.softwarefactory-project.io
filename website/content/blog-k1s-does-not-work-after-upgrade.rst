K1S is not working properly after upgrade
#########################################

:date: 2022-05-25 11:00
:category: blog
:authors: sf

The k1s hypervisor might not work properly after update Centos instance and
after upgrading Software Factory Project to the new release recently.

If the hypervisor is not working as expected, we suggest to downgrade the
podman package from package `podman-1.6.4-32` to `podman-1.6.4-29`.

To verify if your deployment is affected by the issue you can run the following command:

.. code-block:: bash

   echo test | podman exec -i interactive-test cat

To install previous podman package version, you can execute command on k1s host:

.. code-block:: bash

   yum downgrade podman-1.6.4-29.el7_9.x86_64

The Software Factory team has reported that issue to the podman community, but
the patch is not released yet.

You can find more information about the issue at https://bugzilla.redhat.com/show_bug.cgi?id=2087994
