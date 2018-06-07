How to setup a Software Factory sandbox
---------------------------------------

:date: 2018-06-12
:category: blog
:authors: Nicolas Hicher

In this article, we will explain how to setup a sandbox to experiment with
Software Factory. The following article explains how to setup a CentOS 7 virtual
machine guest based on VirtualBox. The sandbox guest will be configured to be
accessible from your host only.

Create the virtual machine
..........................

The first step is to create a CentOS 7 virtual machine.

* download the `centos minimal iso <https://www.centos.org/download/>`_
* create the virtual machine using VirtualBox Manager with:

- 20G hdd
- 4G ram
- hostname: sftests.com

Do not forget to add a root password, it will be used to connect to the virtual
machine later.

After the installation, stop the virtual machine to finalise the configuration.
The easiest solution to access to your instance from your terminal and browser is
to create a second interface within the settings of the virtual machine with the
type *Host-only adaptater*. Then start the virtual machine, and use *ip address*
from the virtual machine terminal to get the network configuration:

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

Add the ip address of the second interface and the hostname in your /etc/hosts file:

.. code-block:: bash

  192.168.56.102 sftests.com

Configure the virtual machine
.............................

Connect to your virtual machine from your host

.. code-block:: bash

  ssh root@sftests.com

Configure firewalld to allow http, https and gerrit access from your host:

.. code-block:: bash

  firewall-cmd --zone=public --permanent --add-service=http
  firewall-cmd --zone=public --permanent --add-service=https
  firewall-cmd --zone=public --permanent --add-port=29418/tcp

Install Software Factory
........................

The next step is to install Software Factory. We will add *hypervisor-oci* to
the arch file to enable containers for check and gate jobs:

Ensure the system is up to date before starting Software Factory installation:

.. code-block:: bash

  yum update -y

Install Software Factory

.. code-block:: bash

  yum install -y https://softwarefactory-project.io/repos/sf-release-3.0.rpm
  yum update -y
  yum install -y sf-config
  echo '      - hypervisor-oci' >> /etc/software-factory/arch.yaml
  sfconfig --enable-insecure-slaves

Validate https access
.....................

Connect to *https://sftests.com* to access to the software factory web interface

.. figure:: images/sf_dashboard.png
   :width: 80%

Configure admin public ssh key
..............................

The next step is to add your ssh pub key to the admin account to be able to
propose review with the admin account. The
admin password is defined in */etc/software-factory/sfconfig.yaml file*

.. code-block:: bash

   awk '/admin_password/ { print $2}' /etc/software-factory/sfconfig.yaml

Go to *https://sftests.com/auth/login* using *Toggle login form* with the admin
account. Then select the *Gerrit* link in the top menu, and edit the setting
of the gerrit admin account:

.. figure:: images/gerrit_settings.png
   :width: 80%

Select *SSH Public Keys* and add your public key (Do not delete the other
defined key, it's used for administrative tasks).

Finaly, you can also add your ssh public key for user root for adminitrative
task (from your host or edit /root/.ssh/authorized_keys on sftests.com):

.. code-block:: bash

  ssh-copy-id root@sftests.com

Snapshot the virtual machine
............................

You can now snapshot the virtual machine to be able to quickly restore a known
state after testing.
