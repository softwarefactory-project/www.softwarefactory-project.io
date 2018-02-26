.. _architecture:

Architecture
============

Software Factory's architecture is modular and defined in a single file called
arch.yaml. This file defines how services are deployed. Each host declares:

* A hostname,
* An IP address,
* A public_url (used for service like zuul-merger),
* A list of components.

For example, to add a new zuul-merger, start a new instance inside the internal
network of the deployment, enable ssh connections by copying the install server
*root* user public ssh key to the authorized_keys of the new instance and
update the arch.yaml with:

.. code-block:: yaml

  # vim /etc/software-factory/arch.yaml # Add new host:
      - host: zm02
        ip: 192.168.0.XXX
        roles:
          - zuul-merger
  # sfconfig


.. _architecture_config_file:

Configuration
-------------

The architecture is defined in /etc/software-factory/arch.yaml:

.. code-block:: yaml

  inventory:
    - name: node01
      ip: 192.168.240.10
      roles:
        - install-server
        - mysql

    - name: node02
      ip: 192.168.240.11
      roles:
        - gerrit

.. note::

  Any modification to the *arch.yaml* file needs to be manually applied with the
  sfconfig script. Run sfconfig after saving the sfconfig.yaml file.


The minimal architecture includes following components:

.. TODO Task: 566 update architecture with all available components
..      create one page per component if needed
..      explain how to use and deploy each component


* install-server
* mysql
* zookeeper
* gateway
* cauth
* `managesf </docs/managesf/>`_
* gitweb
* `gerrit </r/Documentation/index.html>`_
* logserver
* `zuul-scheduler </docs/zuul/>`_
* `zuul-executor </docs/zuul/>`_
* `zuul-web </docs/zuul/>`_
* `nodepool-launcher </docs/nodepool/>`_

Optional services can be enabled:

* zuul-merger
* nodepool-builder
* hypervisor-oci
* rabbitmq
* etherpad
* lodgeit
* gerritbot
* logserver
* nodepool-builder
* murmur
* elasticsearch
* job-logs-gearman-client
* job-logs-gearman-worker
* logstash
* kibana
* mirror
* storyboard
* storyboard-webclient
* repoxplorer
* firehose
* pages
* hydrant
* influxdb
* grafana


.. note::

   Check the :ref:`nodepool documentation<nodepool-operator-oci>` to learn
   how to configure the hypervisor-oci role to enable container providers in Nodepool.

.. _architecture_extending:

Extending the architecture
--------------------------

To deploy a specific service on a dedicated instance:

* Start a new instance on the same network as the install-server with the desired flavor
* Attach a dedicated volume if needed
* Make sure other instances security group allows network access from the new instance
* Add the root public ssh key (install-server:/root/.ssh/id_rsa.pub) to the new instance
  /root/.ssh/authorized_keys,
* Make sure the new instance's ssh service is configured to allow public key authentication,
* Add the new instance to the arch inventory and set its IP address,
* Add desired services in the roles list (e.g., elasticsearch), and
* Run sfconfig to reconfigure the deployment.

See `sf-config/refarch`_ directory for examples of valid architectures.

.. _sf-config/refarch: https://softwarefactory-project.io/r/gitweb?p=software-factory/sf-config.git;a=tree;f=refarch

.. _architecture_migrate_service:

Migrate a service to a dedicated instance
-----------------------------------------

This procedure demonstrates how to run the log indexation services (ELK stack) on a dedicated instance:

* First stop and disable all elk related services (elasticsearch, logstash, kibana, log-gearman-client and log-gearman-worker)
* Copy the current data, e.g.: rsync -a /var/lib/elasticsearch/ new_instance_ip:/var/lib/elasticsearch/
* Add the new instances and roles to the /etc/software-factory/arch.yaml file:

.. code-block:: yaml

  inventory:
    - name: elk
      ip: new_instance_ip
      roles:
        - elasticsearch
        - logstash
	- kibana
        - log-gearman-client
        - log-gearman-worker

* Run sfconfig to apply the architecture modification
