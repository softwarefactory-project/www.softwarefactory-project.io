:orphan:

.. _deploy:

#######################
Deploy Software Factory
#######################

This section presents how to properly deploy Software Factory services.


Overview
========

Follow these steps for a successful deployment:

* Use a CentOS-7 system or grab the `provided disk image <https://softwarefactory-project.io/releases/sf-2.7/sf-2.7.qcow2>`_
  with all the components pre-installed.

* Create as many host instances as needed according to the
  :ref:`recommended requirements<deployment_requirements>`.

* Setup :ref:`network access control` and make sure the install-server can ssh
  into the other instance using the root user ssh key.

* On the install server, do a :ref:`minimal configuration<deployment_configuration>`.

* Run sfconfig. It will execute the following steps:

  * Generate an Ansible playbook based on the arch.yaml file,
  * Generate secrets and group_vars based on the sfconfig.yaml file, and
  * Run the playbook to:

    * Install the services if needed.
    * Configure and start the services.
    * Setup the config and zuul-jobs repositories.
    * Validate the deployment with test-infra.


Alternatively, you can also follow one of these
:ref:`automated deployments guide <deployment_image_based>` based on a custom disk
image.


.. _deployment_requirements:

Requirements
============

Minimum
-------

Software Factory needs at least one instance, referred to as the *install-server*.


An all-in-one deployment requires at least a single instance with 4CPU, 8GB of memory
and 20GB of disk.

Recommended
-----------

It is recommended to distribute the components accross multiple instances
to isolate the services and avoid a single point of failure.

The following table gives some sizing recommendations depending on the services
you intend to run on a given instance:

========== ========= =======
 Name       Disk      Ram
========== ========= =======
Zuul        1GB       2GB
Nodepool    20GB      2GB
Zookeeper   1GB       1GB
Logstash    40GB      2GB
Logserver   40GB
Gerrit      40GB      2GB
Others      5GB       1GB
========== ========= =======


.. _network access control:

Network Access Control
======================

All external network access goes through the gateway instance and the FQDN
needs to resolve to the instance IP:

============================ ======================================
 Port                         Service
============================ ======================================
443                           the web interface (HTTPS)
29418                         gerrit access to submit code review
1883 and 1884                 MQTT events (Firehose)
64738 (TCP) and 64738 (UDP)   mumble (the audio conference service)
============================ ======================================

Operators will need SSH access to the install-server to manage the services.

Internal instances need to be accessible to each other for many shared services,
so it is recommended to run all the services instances within a single service network.
For example, the following services are consumed by:

====================== =========================
 Service name           Consumers
====================== =========================
SQL server              Most services
Gearman/Zookeeper       Zuul/Nodepool
Gearman/Elasticsearch   Log-gearman for logstash
====================== =========================

Test instances (slaves) need to be isolated from the service network; however
the following ports must be open:

====================== =========================
 Provider type          TCP Port access for Zuul
====================== =========================
 OpenStack              22
 OpenContainer          22022 - 65035
====================== =========================

.. _deployment_configuration:

Deployment configuration
========================

Deployment and maintenance tasks (such as backup/restore or upgrade) are
performed through a node called the install-server which acts as a jump server.
Make sure this instance can ssh into the other instances via public key authentication.
The steps below need to be performed on the install-server.

If you used a vanilla CentOS-7 system, you have to install the sf-config package
on the install-server first:

.. code-block:: bash

  yum install -y https://softwarefactory-project.io/repos/sf-release-2.7.rpm
  yum update -y
  yum install -y sf-config


To enable extra services (such as logstash) or to distribute services on
multiple instances, you have to edit the arch.yaml file
(see the :ref:`architecture documentation<architecture>` for more details).
For example to add a logstash service on a dedicated instance, edit
the /etc/software-factory/arch.yaml file like this:

.. code-block:: yaml

  - name: elk
    ip: 192.168.XXX.YYY
    roles:
      - elasticsearch
      - job-logs-gearman-client
      - job-logs-gearman-worker
      - logstash
      - kibana


.. note::

  You can find reference architectures in /usr/share/sf-config/refarch, for
  example the softwarefactory-project.io.yaml is the architecture we use in
  our production deployment.


From the install-server, you can also set operator settings, such as external
service credentials, in the sfconfig.yaml file
(see the :ref:`configuration documentation<configure>` for more details).
For example, to define your fqdn, the admin password and an OpenStack
cloud providers, edit the /etc/software-factory/sfconfig.yaml file like this:

.. code-block:: yaml

  fqdn: example.com
  authentication:
    admin_password: super_secret
  nodepool3:
    providers:
      - name: default
        auth_url: https://cloud.example.com/v3
        project_name: tenantname
        username: username
        password: secret
        region_name: regionOne
        user_domain_name: Default
        project_domain_name: Default

Finally, to setup and start the services, run:

.. code-block:: bash

  sfconfig


Access Software Factory
=======================

The Dashboard is available at https://FQDN and the *admin* user can authenticate
using "Internal Login". If you used the default domain *sftests.com* then the default
admin password is *userpass*.

Congratulations, you successfully deployed Software Factory.
You can now head over to the :ref:`architecture documentation<architecture>` to
check what services can be enabled, or read the
:ref:`configuration documentation<configure>` to check all services settings.

Lastly you can learn more about operations such as maintenance, backup and
upgrade in the :ref:`management documentation<management>`.

Otherwise you can find below some guides to help you automate deployment steps
so that you can easily reproduce a deployment.


.. _deployment_image_based:

Image based deployment
======================

This documentation describes 3 solutions to install Software Factory using
images provided by the project:

* :ref:`on openstack using heat <deployment_image_based_heat>`
* :ref:`on openstack using nova <deployment_image_based_nova>`
* :ref:`on kvm host using libvirtd <deployment_image_based_kvm>`

OpenStack based deployment
--------------------------

To simplify and speed up the deployment process, a pre-built image should be used.
A new diskimage is created for each release.


.. _deployment_image_based_install_image:

Prepare the installation image
..............................

The Software Factory base image first needs to be created in Glance:

.. code-block:: bash

  $ curl -O https://softwarefactory-project.io/releases/sf-2.7/sf-2.7.qcow2
  $ openstack image create sf-2.7.0 --disk-format qcow2 --container-format bare --file softwarefactory-C7.0-2.7.0.img.qcow2

.. _deployment_image_based_heat:

Deploying with Heat
...................

Heat templates are available to automate the deployment process of different reference architectures.

These templates require the following parameters:

* ``image_id``: The Software Factory image UUID. This is obtained when
  uploading the `installation image <Prepare the installation image>`_.
* ``external_network``: The external Neutron network UUID. This is obtained by
  querying Neutron with ``openstack network list``.
* ``domain``: The fully qualified domain name (FQDN) of the deployment.
* ``key_name``: The name of the keypair to provision on the servers. You can
  import a keypair in Nova with ``openstack keypair create`` or list existing
  keypairs with ``openstack keypair list``.

First, retrieve the template you're interested in, for example 'all in one':

.. code-block:: bash

 $ curl -O https://softwarefactory-project.io/releases/sf-2.7/sf-2.7-allinone.hot

Then, create the Heat stack:

.. code-block:: bash

  $ openstack stack create sf_stack --template softwarefactory-C7.0-2.7.0-allinone.hot \
      --parameter key_name=<key-name> \
      --parameter domain=<fqdn> \
      --parameter image_id=<glance image UUID> \
      --parameter external_network=<neutron external network uuid> \
      --parameter flavor=<flavor>

Once the stack is created jump to the section :ref:`Configuration and reconfiguration <configure_reconfigure>`.


.. _deployment_image_based_nova:

Deploying with Nova
...................

When Heat is not available, Software Factory can also be deployed manually using the Nova CLI, or
using the web UI of your cloud provider. You should first :ref:`install the software
factory image <deployment_image_based_install_image>`

Once the VM is created jump to the section :ref:`Configuration and reconfiguration <configure_reconfigure>`.
Don't forget to manage by yourself the security groups for the SF deployment :ref:`Network Access <network access control>`.

.. _deployment_image_based_kvm:

KVM based deployment
--------------------

Prerequisites
.............

Ensure the following packages are installed (example for CentOS7 system)

.. code-block:: bash

  $ sudo yum install -y libvirt virt-install genisoimage qemu-img
  $ sudo systemctl start libvirtd && sudo systemctl enable libvirtd

.. note::

  when you start libvirtd, a bridge named virbr0 is created. (using
  192.168.122.0/24 or 192.168.124.0/24 networks).

Prepare the installation image
..............................

The Software Factory image needs to be downloaded on your kvm host

.. code-block:: bash

  $ curl -O https://softwarefactory-project.io/releases/sf-2.7/sf-2.7.qcow2
  $ sudo mv sf-2.7.qcow2 /var/lib/libvirt/images
  $ sudo qemu-img resize /var/lib/libvirt/images/sf-2.7.qcow2 +20G

Prepare the cloud-init configuration files
..........................................

It's possible to use cloud-init without running a network service by providing
the meta-data and user-data files to the local vm on a iso9660 filesystem.

First, you have to adapt the following values:

.. code-block:: bash

  $ my_hostname=managesf
  $ my_domain=sftests.com
  $ my_ssh_pubkey=$(cat ~/.ssh/id_rsa.pub)

* create the user-data file

.. code-block:: bash

  $ cat << EOF >> user-data
  #cloud-config
  hostname: $my_hostname
  fqdn: $my_hostname.$my_domain

  groups:
    - centos

  users:
    - default
    - name: root
      ssh-authorized-keys:
        - $my_ssh_pubkey
    - name: centos
      gecos: RedHat Openstack User
      shell: /bin/bash
      primary-group: centos
      ssh-authorized-keys:
        - $my_ssh_pubkey
      sudo:
        - ALL=(ALL) NOPASSWD:ALL

  write_files:
    - path: /etc/sysconfig/network-scripts/ifcfg-eth0
      content: |
        DEVICE="eth0"
        ONBOOT="yes"
        TYPE="Ethernet"
        BOOTPROTO="none"
        IPADDR=192.168.124.10
        PREFIX=24
        GATEWAY=192.168.124.1
        DNS1=192.168.124.1
    - path: /etc/sysconfig/network
      content: |
        NETWORKING=yes
        NOZEROCONF=no
        HOSTNAME=$my_hostname
    - path: /etc/sysctl.conf
      content: |
        net.ipv4.ip_forward = 1

  runcmd:
    - /usr/sbin/sysctl -p
    - /usr/bin/sed  -i "s/\(127.0.0.1\)[[:space:]]*\(localhost.*\)/\1 $my_hostname.$my_domain $my_hostname \2/" /etc/hosts
    - /usr/bin/systemctl restart network
    - /usr/bin/sed  -i "s/requiretty/\!requiretty/" /etc/sudoers
  EOF

* create the meta-data file

.. code-block:: bash

  $ cat << EOF >> meta-data
  instance-id: $my_hostname-01
  local-hostname: $my_hostname.$my_domain
  EOF

* generate an iso image with user-data and meta-data files

.. code-block:: bash

  $ sudo genisoimage -output /var/lib/libvirt/images/$my_hostname.iso -volid cidata -joliet -rock user-data meta-data

* create a storage disk for the instance

.. code-block:: bash

  $ sudo qemu-img create -f qcow2 -b /var/lib/libvirt/images/sf-2.7.qcow2 /var/lib/libvirt/images/$my_hostname.qcow2

* boot the instance

.. code-block:: bash

  $ sudo virt-install --connect=qemu:///system --accelerate --boot hd --noautoconsole --graphics vnc --disk /var/lib/libvirt/images/$my_hostname.qcow2 --disk path=/var/lib/libvirt/images/$my_hostname.iso,device=cdrom --network bridge=virbr0,model=virtio --os-variant rhel7 --vcpus=4 --cpu host --ram 4096 --name $my_hostname

* You can connect to your instance using ssh, it's possible to use "virsh
  console $my_hostname" during the boot process to following the boot sequence.

.. code-block:: bash

  $ ssh 192.168.124.10 -l centos

Once the virtual machine is available, jump to the section :ref:`Configuration and reconfiguration <configure_reconfigure>`.
