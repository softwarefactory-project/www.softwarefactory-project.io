.. _upgrade:

Upgrade Software Factory
========================

To maintain the deployment up-to-date, simply uses:

.. code-block:: bash

  yum update -y

To upgrade to a new release of Software Factory, for example the version 3.1:

.. code-block:: bash

  yum install -y https://softwarefactory-project.io/repos/sf-release-3.1.rpm
  yum update -y sf-config
  sfconfig --upgrade

This process turns off all the services and perform data upgrade if necessary.
