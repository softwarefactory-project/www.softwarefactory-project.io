How to setup a Software Factory sandbox
---------------------------------------

:date: 2018-08-07
:modified: 2018-12-12
:category: blog
:authors: Nicolas Hicher
:tags: zuul-hands-on-series

In this article, we will explain how to setup a sandbox in order to experiment with
Software Factory. The following article explains how to setup a CentOS 7 virtual
machine guest based on VirtualBox. Feel free to adapt the following to
the hypervisor of your choice. The sandbox guest will be configured to be accessible
from your host only.

This article is part of the `Zuul hands-on series <{tag}zuul-hands-on-series>`_.

Create the virtual machine
..........................

The first step is to create a CentOS 7 virtual machine.

* download the `CentOS 7 minimal iso <https://www.centos.org/download/>`_
* create the virtual machine using VirtualBox Manager with the following settings:

  - 20G HDD
  - 4G RAM
  - hostname: sftests.com

During the installation process, do not forget to activate the network and
set the hostname in the *NETWORK & HOST NAME* panel.

After the installation, shut down the virtual machine to finalize the configuration.
For easy access to your instance from a terminal and browser,
open the virtual machine settings in VirtualBox and create an additional network
interface attached to the *Host-only adapter* . Then start the virtual machine,
and type *ip address* in the virtual machine's terminal to get the network
configuration:

.. code-block:: bash

  [root@managesf.sftests.com ~]# ip a
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
      ...
  2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
      link/ether 08:00:27:c5:69:3c brd ff:ff:ff:ff:ff:ff
      inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic enp0s3
         valid_lft 85327sec preferred_lft 85327sec
  3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
      link/ether 08:00:27:23:d3:1b brd ff:ff:ff:ff:ff:ff
      inet 192.168.56.102/24 brd 192.168.56.255 scope global noprefixroute dynamic enp0s8
         valid_lft 1133sec preferred_lft 1133sec

Configure access to the virtual machine
.......................................

Add the IP address of the second interface and the hostname in your /etc/hosts
file (ie on the VirtualBox host), for example:

.. code-block:: bash

  192.168.56.102 sftests.com

Configure the virtual machine
.............................

You can authorize your SSH public key with the root user to allow password-less
authentication:

.. code-block:: bash

  ssh-copy-id root@sftests.com

Connect to your virtual machine from your host:

.. code-block:: bash

  ssh root@sftests.com

Configure firewalld to allow http, https and gerrit access from your host:

.. code-block:: bash

  firewall-cmd --add-service=http --add-service=https
  firewall-cmd --add-port=29418/tcp
  firewall-cmd --runtime-to-permanent

Install Software Factory
........................

The next step is to install Software Factory. We will add *hypervisor-runc* to
the architecture file to enable containers in check and gating jobs:

First, ensure the system is up to date before installing Software Factory:

.. code-block:: bash

  yum update -y

Then, install Software Factory, this will take ~15 minutes to
download, install and configure services:

.. code-block:: bash

  yum install -y https://softwarefactory-project.io/repos/sf-release-3.2.rpm
  yum update -y
  yum install -y sf-config
  echo '      - hypervisor-runc' >> /etc/software-factory/arch.yaml
  echo 'gateway_force_fqdn_redirection: False' > /etc/software-factory/custom-vars.yaml
  echo 'enable_insecure_slaves: True' >> /etc/software-factory/custom-vars.yaml
  sfconfig

Validate https access
.....................

Connect to `<https://sftests.com>`_ to access to the software factory web interface

.. figure:: images/sf_dashboard.png
   :width: 80%

Configure admin public SSH key
..............................

The next step is to add your SSH public key to the admin account, so that you
can submit reviews with the admin account. The
admin password is defined in the */etc/software-factory/sfconfig.yaml* file.

.. code-block:: bash

   awk '/admin_password/ { print $2}' /etc/software-factory/sfconfig.yaml

Go to `<https://sftests.com/auth/login>`_ and log in as admin by clicking on
*Toggle login form*. Then select the *Gerrit* link in the top menu, and click on
"Settings" to edit the admin account:

.. figure:: images/gerrit_settings.png
   :width: 80%

Select *SSH Public Keys* and add your public key (Do not delete the other
defined key, it's used for administrative tasks).

Snapshot the virtual machine
............................

You can now snapshot the virtual machine to be able to quickly restore a known
state after testing.
