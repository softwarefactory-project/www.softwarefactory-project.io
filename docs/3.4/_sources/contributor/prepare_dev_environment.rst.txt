.. _prepare_dev_environment:

Prepare a development environment
---------------------------------

Software Factory runs and is developed on CentOS 7. Provision a CentOS 7 system, then install the following prerequisites:

.. code-block:: bash

 sudo yum install -y centos-release-scl-rh
 sudo yum install -y https://rdoproject.org/repos/openstack-queens/rdo-release-queens.rpm
 sudo yum install -y git git-review vim-enhanced tmux curl rpmdevtools createrepo mock python-jinja2 ansible
 sudo /usr/sbin/usermod -a -G mock $USER
 newgrp mock

It is recommended that your Centos 7 installation be dedicated to Software Factory development
to avoid conflicts with unrelated components.

Then you will need to check out the Software Factory repositories:

.. code-block:: bash

 mkdir software-factory scl
 git clone https://softwarefactory-project.io/r/software-factory/sfinfo software-factory/sfinfo
 git clone https://softwarefactory-project.io/r/software-factory/sf-ci
 ln -s software-factory/sfinfo/zuul_rpm_build.py .
 ln -s software-factory/sfinfo/sf-master.yaml distro.yaml

The file *sfinfo/sf-master.yaml* contains the references of all the repositories that form
the Software Factory distribution.
