.. _deploy:

#######################
Deploy Software Factory
#######################

This section presents how to properly deploy Software Factory services.


Overview
========

.. warning::

    Software Factory is not compatible with EPEL. Please make sure that
    systems part of your Software Factory deployment does not
    have the epel-release package installed.

Follow these steps for a successful deployment:

* Use a CentOS-7 system.

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

================= ===== =======================================================
 Name              Ram   Disk
================= ===== =======================================================
zuul-executor      2GB   Projects git clones all the repositories and job logs
zuul-merger        1GB   Projects git clones
nodepool-builder   1GB   Disk image builder, e.g. 20GB
zookeeper          1GB   1GB
elk                2GB   Jobs logs over retention period, e.g. 40GB
logserver          1GB   Jobs logs over retention period, e.g. 40GB
gerrit             2GB   Projects git clones and patchset history, e.g. 20GB
others             1GB   5GB
================= ===== =======================================================

* Zookeeper needs 1GB of memory for every 10 nodes it manages
* Zuul executors need 2GB of memory per vCPU, and each vCPU can handle
  approximately 4 concurrent jobs.

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

.. code-block:: bash

  yum install -y https://softwarefactory-project.io/repos/sf-release-3.2.rpm
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
  nodepool:
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
using "Internal Login".

Congratulations, you successfully deployed Software Factory.
You can now head over to the :ref:`architecture documentation<architecture>` to
check what services can be enabled, or read the
:ref:`configuration documentation<configure>` to check all services settings.

Lastly you can learn more about operations such as maintenance, backup and
upgrade in the :ref:`management documentation<management>`.

Otherwise you can find below some guides to help you automate deployment steps
so that you can easily reproduce a deployment.
