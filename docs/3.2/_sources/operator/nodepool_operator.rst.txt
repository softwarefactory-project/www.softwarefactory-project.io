.. note::

  This is a lightweight documentation intended to get operators started with setting
  up the Nodepool service. For more insight on what Nodepool can do, please refer
  to its upstream documentation_.

.. _documentation: https://docs.openstack.org/infra/nodepool

Operate nodepool
================

The nodepool service is installed with the rh-python35 software collections:

* The configuration is located in /etc/nodepool
* The logs are written to /var/log/nodepool
* The services are prefixed with rh-python35-

A convenient wrapper for the command line is installed in /usr/bin/nodepool.


Architecture
------------

Minimal
.......

The **nodepool-launcher** component is required in the architecture file to
enable nodepool.

This minimal deployment uses an OpenStack cloud provider, where images available
to build test nodes will be managed through the OpenStack cloud itself, for example
with Glance.

RunC containers
...............

To use the RunC container driver, add the **hypervisor-runc** component to the
architecture file or check the
:ref:`RunC manual setup<nodepool-manual-operator-runc>` below.


Diskimage-builder
.................

To manage custom images through the config repository, built using diskimage-builder
(DIB), add the **nodepool-builder** component in the architecture file.

.. tip::

  With diskimage-builder, Software Factory users can customize test images without
  the need for specific authorizations on the OpenStack project. And since custom
  images definitions are subject to reviews on the config repository, operators
  can choose to allow or reject these images.


Add a cloud provider
--------------------

To add a cloud provider, an OpenStack cloud account is required.
It is highly recommended to use a project dedicated to
Nodepool.

The slave instances inherit the project's "default" security group for access
rules. Therefore the project's "default" security group must allow incoming SSH
traffic (TCP/22) and incoming log stream port (TCP/19885) from the zuul-executor
node. Please refer to `OpenStack's documentation
<https://docs.openstack.org/nova/queens/admin/security-groups.html>`_ to find out
how to modify security groups.

In order to configure an OpenStack provider you need
to add in sfconfig.yaml the cloud client information, below is an example of
configuration.

.. code-block:: yaml

 nodepool:
   providers:
     - name: default
       auth_url: http://localhost:5000/v2.0
       project_name: 'tenantname'
       username: 'user'
       password: 'secret'
       image_format: raw
       region_name: ''
       # Uncomment and set domain-related values when using a keystone v3 authentication endpoint
       # user_domain_name: Default
       # project_domain_name: Default

To apply the configuration you need to run again the sfconfig script.

You should be able to validate the configuration via the nodepool client by checking if
Nodepool is able to authenticate on the cloud account.

.. code-block:: bash

 $ nodepool list
 $ nodepool image-list


See the :ref:`Nodepool user documentation<nodepool-user>` for configuring additional
settings on the providers as well as defining labels and diskimages.

As an administrator, it can be really useful to check
/var/log/nodepool to debug the Nodepool configuration.


.. _nodepool-operator-runc:

Add a container provider
------------------------

Software Factory's Nodepool service comes with a new RunC (OpenContainer) driver
based on a simple runc implementation. It is still under review and not
integrated in the upstream version of Nodepool yet, however it is available in
Software Factory to enable a lightweight environment for Zuul jobs,
instead of full-fledged OpenStack instances.

The driver will start containerized *sshd* processes using a TCP port in a
range from 22022 to 65535. Make sure the RunC provider host accepts incoming
traffic on these ports from the zuul-executor.


Setup an RunC provider using the hypervisor-runc role
.....................................................

The role **hypervisor-runc** can be added to the architecture file. This role
will install the requirements and configure the node.
This role must be installed on a Centos 7 instance. Containers *bind mount*
the local host's filesystem, that means you don't have to configure an image,
what is installed on the instance is available inside the containers.
The role can be defined on multiple nodes in order to scale.

Please refer to :ref:`Extending the architecture<architecture_extending>` for
adding a node to the architecture, then run sfconfig.

.. warning::

  The RunC provider doesn't enforce network isolation and slaves need to run on
  a dedicated instance/network. sfconfig will refuse to install this role on a
  server where Software Factory services are running. Nevertheless you can
  bypass this protection by using the sfconfig's
  option *--enable-insecure-slaves*.

.. note::

  Note that *config/nodepool/_local_hypervisor_runc.yaml* will by automatically
  updated in the config repository, making RunC provider(s) available in
  Nodepool.


.. _nodepool-manual-operator-runc:

Manual setup of an RunC container provider
..........................................

Alternatively, you can setup a container provider manually using one or more
dedicated server(s), which could be running Fedora, CentOS, RHEL or any other
Linux distribution:

* Create a new user, for example: useradd -m zuul-worker
* Authorize nodepool to connect as root: copy the
  /var/lib/nodepool/.ssh/id_rsa.pub to /root/.ssh/authorized_keys
* Authorize zuul to connect to the new user: copy the
  /var/lib/zuul/.ssh/id_rsa.pub to /home/zuul-worker/.ssh/authorized_keys
* Create the working directory: mkdir /home/zuul-worker/src
* Install runc and any other test packages such as yamllint, rpm-build, ...
* Authorize network connection from software factory on port 22 and
  22022 to 65535

Then register the provider to the nodepool configuration: in the config
repository add a new file in /root/config/nodepool/new-runc-provider.yaml:

.. code-block:: yaml

  labels:
    - name: new-container

  providers:
    - name: new-provider
      driver: runC
      pools:
        - name: instance-hostname-or-ip
          max-servers: instance-core-number
          labels:
            - name: new-container
              username: zuul-worker

Once this config repo change is merged, any job can now use this new-container
label.


Use custom container images with the RunC provider
..................................................

By default, the server root filesystem is used for the container rootfs, but
you can create and use different rootfs for the containers. To create a new
rootfs, do:

* Extract a rootfs, for example from a cloud disk image, e.g. in /srv/centos-6
* Create server ssh keys: chroot /srv/centos-6 /usr/sbin/sshd-keygen
* Create a new user: chroot /srv/centos-6 useradd -m zuul-worker
* Install test packages: chroot /srv/centos-6 yum install -y rpm-build
* Authorize zuul to connect to the new user: copy the
  /var/lib/zuul/.ssh/id_rsa.pub to
  /srv/centos-6/home/zuul-worker/.ssh/authorized_keys

Then create a new label in the nodepool configuration using the 'path'
attribute to set the new rootfs, for example:

.. code-block:: yaml

  labels:
    - name: centos-6-container

  providers:
    - name: new-provider
      driver: runC
      pools:
        - name: instance-hostname-or-ip
          max-servers: install-core-number
          labels:
            - name: centos-6-container
              username: zuul-worker
              path: /srv/centos-6


Debug container creation failure
................................

If for some reason containers fail to start, here are some tips to investigate
the errors:

* Look for failure in logs, e.g.:
  grep nodepool.driver.runc /var/log/nodepool/launcher.log
* Catch container start failures by running runc manually on the host server:

.. code-block:: bash

  runc run --bundle /var/lib/nodepool/runc/$nodepool-node-server-id debug-run

* Execute command directly:

.. code-block:: bash

  runc list
  runc exec $container-id bash

* Verify the runtime RunC specification config.json file located in the bundle
  directory
* Check that zuul can connect to the server on ports higher than 22022


.. _restart-nodepool-services:


Restart Nodepool services
-------------------------

The *nodepool_restart.yml* playbook stop and restart Nodepool launcher
services.

.. code-block:: yaml

  ansible-playbook /var/lib/software-factory/ansible/nodepool_restart.yml


Useful commands
---------------

List slave instances and their status (used, building ...). Use the *--detail**
option to get the public IP of the instances:

.. code-block:: bash

 $ nodepool list

Trigger an diskimage build. The image will be automatically uploaded on the
provider(s) after a successful build:

.. code-block:: bash

 $ nodepool image-build *image-name*

Build logs are available in */var/www/nodepool-log/* on
the nodepool-builder node but also via https://sftests.com/nodepool-log/.

List nodepool instance images available on the configured providers and their
status:

.. code-block:: bash

 $ nodepool image-list

List instance diskimages built by Disk Image Builder (DIB) and their status:

.. code-block:: bash

 $ nodepool dib-image-list
