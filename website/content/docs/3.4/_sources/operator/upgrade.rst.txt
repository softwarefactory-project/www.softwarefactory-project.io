.. _upgrade:

Upgrade Software Factory
========================

To maintain the Software Factory nodes (part of the architecture) up to date,
simply uses:

.. code-block:: bash

    sfconfig --update

The command takes care of updating packages (system and software factory) on
all nodes. Some services may be restarted if their version changed and sfconfig
will run migration tasks automatically if needed.

To upgrade to a new release of Software Factory:

.. code-block:: bash

  yum install -y https://softwarefactory-project.io/repos/sf-release-3.4.rpm
  yum update -y sf-config
  sfconfig --update

Prevent services auto-restart
-----------------------------

The update process restarts services when their version changed. This
behavior can be disabled for critical services like Zuul and Nodepool. To do
so add the following extra vars to the *custom-vars.yaml file*.
Default is False.

.. code-block:: bash

  echo "disable_zuul_autorestart: True" >> /etc/software-factory/custom-vars.yaml
  echo "disable_nodepool_autorestart: True" >> /etc/software-factory/custom-vars.yaml

Then, you can restart those services by following the instuctions below:

 - :ref:`Restart Zuul services <restart-zuul-services>`
 - :ref:`Restart Nodepool services <restart-nodepool-services>`
