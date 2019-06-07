.. _quickstart:

Quick Start
===========

This section presents how to quickly get the services up and running in a few
minutes. This allows you to easily test the services and check how Software
Factory works. When you are satisfied, check the :ref:`configuration file<configure>`
to customize the settings and the :ref:`architecture file<architecture>` to
enable extra services.
Also check the :ref:`deployment documentation <deploy>` for deployment options
and how to setup network access control.


.. _allinone-quickstart:

Minimal quickstart
------------------

On a CentOS-7 system, deploy the basic services (managesf, gerrit, zuul and
nodepool) using these commands:

.. code-block:: bash

  yum install -y https://softwarefactory-project.io/repos/sf-release-3.3.rpm
  yum install -y sf-config
  sfconfig --provision-demo

.. note::

   By default the deployment will use "sftests.com" for the FQDN, you might
   want to set it locally in your /etc/hosts so that the web interface works
   properly.


.. _runc-quickstart:

RunC provider quickstart
------------------------

The Nodepool service integrated in Software Factory comes with a runC provider
driver to enable simple static node usage. The sfconfig configuration
management comes with a **hypervisor-runc** role that you can use to quickly
setup and configure a test environment.

For this quickstart, we will use the main instance as the hypervisor:

.. code-block:: bash

  echo "      - hypervisor-runc" >> /etc/software-factory/arch.yaml
  sfconfig --enable-insecure-slaves

.. note::

  Because the container doesn't have network isolation, we have to use a sfconfig
  argument to enable the main host as a nodepool provider. Please check the
  the :ref:`nodepool operator doc<nodepool-operator-runc>` to properly deploy
  one or many dedicated instances to use as nodepool containers providers.

Sfconfig will automatically update the config repository and create some ready
to use slaves so that you can run zuul tests without an OpenStack account.
Running "nodepool list" will show 2 *runc-centos* slaves.


.. _tpci-quickstart:

Third-Party-CI quickstart
-------------------------

To configure an external gerrit such as review.openstack.org, you'll need
to manually create a user on the remote gerrit. For openstack.org,
follow `this guide <https://docs.openstack.org/infra/system-config/third_party.html#creating-a-service-account>`_ to configure it.

It's recommended to first deploy a local installation, before adding
the external gerrit. In that case, after your local deployment is validated,
add the local zuul ssh public key (located here: /var/lib/software-factory/bootstrap-data/ssh_keys/zuul_rsa.pub)
to the remote `user ssh key setting page <https://review.openstack.org/r/#/settings/ssh-keys>`_.
Then add the new gerrit connection to /etc/software-factory/sfconfig.yaml file:

.. code-block:: yaml

  zuul:
    gerrit_connections:
      - name: review.openstack.org
        hostname: review.openstack.org
        port: 29418
        puburl: https://review.openstack.org
        username: external-gerrit-user-name
        # optional canonical_hostname
        canonical_hostname: git.openstack.org
