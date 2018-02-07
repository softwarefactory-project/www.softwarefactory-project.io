.. _nodepool-user:

.. warning::

   Nodepool (v2) is deprecated and will be removed in Software Factory 3.0


Nodepool configuration
======================

Disk images and labels definitions are set in Software Factory's **config** repository.

Clone the config repository and modify the file "config/nodepool/nodepool.yaml"
as shown below:

.. code-block:: yaml

  diskimages:
    - name: dib-centos-7
      elements:
        - centos-minimal
        - nodepool-minimal
        - sf-zuul-worker

  labels:
    - name: centos-7
      image: centos-7
      min-ready: 1
      providers:
        - name: default

  providers:
    - name: default
      cloud: default
      clean-floating-ips: true
      image-type: raw
      max-servers: 10
      boot-timeout: 120
      pool: nova
      rate: 10.0
      networks:
        - name: slave-net-name
      images:
        - name: centos-7
          diskimage: dib-centos-7
          username: jenkins
          min-ram: 1024


When submitting this change to the config repository, Software Factory will perform a syntax
check and will allow you (or not) to merge the change. Once merged
the new configuration will be loaded by the Nodepool service. This will trigger
the following on the cloud provider(s) if relevant:

 * A VM is spawned (with "template" in its name)
 * After the execution of the *base.sh* script, a snapshot of the VM is created
 * The VM is destroyed and the snapshot is made available
 * At least one VM is spawned based on the snapshot
 * A floating ip is attached to the new VM
 * The new VM is attached to the build executor as a worker node

Using the config repository, Software Factory users can provide their own build scripts for
specific worker nodes as well as custom labels for their jobs' needs. The worker nodes
are used only once for one specific build, and are destroyed upon the build's completion.
This has several advantages:

 * A clean, reproducible environment for each build
 * A job may have full system access (root) with interfering with anything else
 * Better resource management as nodes are only up when needed

.. _diskimage-elements:

Using extra elements
--------------------

All `diskimage-builder elements <https://docs.openstack.org/developer/diskimage-builder/elements.html>`_
as well as `sf-elements <https://softwarefactory-project.io/r/gitweb?p=software-factory/sf-elements.git;a=tree;f=elements>`_
are available to define a nodepool image. For example you can:

* Replace *centos7* by *fedora* or *gentoo* to change the base OS
* Use *selinux-permissive* to set selinux in permissive mode
* Use *pip-and-virtualenv* to install packages from PyPI
* Use *source-repositories* to provision a git repository


Adding custom elements
----------------------

To customize an image, new diskimage builder elements can be added to the **nodepool/elements** directory in the config repository.
For example, to add python 3.4 to a CentOS-based system, you need to create this element:

.. code-block:: bash

  mkdir nodepool/elements/python34-epel
  echo -e 'epel\npackage-installs' > nodepool/elements/python34-epel/element-deps
  echo 'python34:' > nodepool/elements/python34-epel/packages.yaml


Then you can add the 'python34-epel' element to an existing image.

Read more about diskimage builder elements `here <https://docs.openstack.org/developer/diskimage-builder/developer/developing_elements.html>`_.
Or look at examples from `sf-elements <https://softwarefactory-project.io/r/gitweb?p=software-factory/sf-elements.git;a=tree;f=elements>`_.


CLI
---

The CLI utility *sfmanager* can be used to interact with nodes that are currently running. The
following actions are supported:

* list nodes, with status information like id, state, age, ip address, base image
* hold a specific node, so that it is not destroyed after it has been consumed for a build
* add a SSH public key to the list of authorized keys on the node, allowing a user to do
  remote operations on the node
* schedule a node for deletion
* list available images

These operations might require specific authorizations defined within Software Factory's policy engine.

You can refer to sfmanager's contextual help for more details.
