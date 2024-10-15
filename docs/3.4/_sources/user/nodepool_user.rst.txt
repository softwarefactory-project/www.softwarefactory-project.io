.. _nodepool-user:

.. note::

  This is a lightweight documentation intended to get users started with defining
  test nodes. For more insight on what Nodepool can do, please refer
  to its upstream documentation_.

.. _documentation: https://docs.openstack.org/infra/nodepool

Nodepool user documentation
===========================

Labels, providers and diskimage are defined in *config/nodepool/*. All the yaml
files present in this directory are merged to create the final Nodepool
configuration. It's recommended to create a file per provider or project so that
it's easier to manage.

Below is an example of a cloud provider configuration and an associated
diskimage/label based on CentOS:

.. code-block:: yaml

  ---
  diskimages:
    - name: centos7
      elements:
        - centos-minimal
        - nodepool-minimal
        - zuul-worker-user

  labels:
    - name: centos7
      min-ready: 1

  providers:
    - name: nodepool-provider
      cloud: default
      clean-floating-ips: true
      image-name-format: '{image_name}-{timestamp}'
      boot-timeout: 120
      rate: 10.0
      diskimages:
        - name: centos7
      pools:
        - name: main
          max-servers: 20
          networks:
             - workers
          labels:
            - name: centos7
              min-ram: 1024
              diskimage: centos7

Cloud provider tuning
---------------------

`Provider settings <https://docs.openstack.org/infra/nodepool/configuration.html#provider>`_
include:

* **rate**: the delay between each API call, set it to 1 or lower for fast operations.
* **clean-floating-ips**: automatically release all unused floating IP addresses.
* **boot-timeout** : the delay to wait for an instance to start, the default value is 60 seconds.

`Labels settings <https://docs.openstack.org/infra/nodepool/configuration.html#pool-labels>`_
include:

* **boot-from-volume**: Use a volume instead of an ephemeral disk.
* **cloud-image**: Use an externally managed image instead of DIB.

Adding extra labels or cloud-image to a provider
------------------------------------------------

Using the "extra-labels" stanza, extra labels or cloud-image can be added to an
existing provider using a dedicated file. For example:

.. code-block:: yaml

  labels:
    - name: custom-label
      min-ready: 1

  extra-labels:
    - provider: default-cloud
      pool: main
      cloud-images:
        - name: c2094f1d-9549-4dc8-99f6-e711d7db1e58
          username: zuul
      labels:
        - name: custom-label
          cloud-image: c2094f1d-9549-4dc8-99f6-e711d7db1e58
          min-ram: 4096


.. _nodepool-virt-customize:

Building Images Using Virt Customize
------------------------------------

It's also possible to use virt-customize instead of diskimage-builder with
the virt-customize roles provided in the config repository.
All the informations are in the *config/nodepool/virt-images/* README.
There is an example playbook to build a fedora rawhide image.

.. note::

   Nested virtualization should be enabled on the nodepool-builder host.



Diskimage elements
------------------

.. _diskimage-elements:

Using extra elements
--------------------

All `diskimage-builder elements <https://docs.openstack.org/developer/diskimage-builder/elements.html>`_
as well as `sf-elements <https://softwarefactory-project.io/r/gitweb?p=software-factory/sf-elements.git;a=tree;f=elements>`_
are available to define a nodepool image. For example you can:

* Replace *centos7* by *fedora*, *debian* or *gentoo* to change the base OS
* Use *selinux-permissive* to set selinux in permissive mode
* Use *pip-and-virtualenv* to install packages from PyPI
* Use *source-repositories* to provision a git repository


Adding custom elements
----------------------

To customize an image, new diskimage builder elements can be added to the
**nodepool/elements** directory in the config repository. For example, to add
python 3.4 to a CentOS-based system, you need to create this element:

.. code-block:: bash

  mkdir nodepool/elements/python34-epel
  echo -e 'epel\npackage-installs' > nodepool/elements/python34-epel/element-deps
  echo 'python34:' > nodepool/elements/python34-epel/packages.yaml


Then you can add the 'python34-epel' element to an existing image.

Read more about diskimage builder elements `here <https://docs.openstack.org/developer/diskimage-builder/developer/developing_elements.html>`_.
Or look at examples from `sf-elements <https://softwarefactory-project.io/r/gitweb?p=software-factory/sf-elements.git;a=tree;f=elements>`_.

.. _nodepool-user-rhel:

Building RHEL images
--------------------

To build a RHEL with DIB, you have to download a RHEL cloud image from
https://access.redhat.com (login required) and ask an operator to put the image
in a directory owned by the nodepool user (:ref:`nodepool dib operator
documentation <nodepool-operator-dib>`). Then you have to provide the
information for registration on the env-var statement (see `rhel-common element
documentation
<https://git.openstack.org/cgit/openstack/diskimage-builder/tree/diskimage_builder/elements/rhel-common/README.rst>`_)
to be able to install packages during the build. The registration password
should be set by an operator on nodepool secure.conf file (:ref:`nodepool dib
operator documentation <nodepool-operator-password>`).

.. code-block:: yaml

  - name: dib-rhel-7
    formats:
      - raw
    elements:
      - rhel7
      - rhel-common
      - nodepool-minimal
      - zuul-worker-user
    env-vars:
      DIB_LOCAL_IMAGE: '/var/lib/nodepool/images/rhel-7.5.qcow2'
      REG_AUTO_ATTACH: true
      REG_USER: $registration_user
      REG_METHOD: portal
