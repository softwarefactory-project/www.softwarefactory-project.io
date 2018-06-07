Zuul Hands on - part 1 - What is Zuul ?
---------------------------------------

:date: 2018-06-13
:category: blog
:authors: Nicolas Hicher

This article is the first of a series about learning Zuul by usage. This series
will start with quite simple use case then will cover more complex jobs
configurations.

In this first article, we will quickly introduce Zuul components and give some
Software Factory integration details.

You can deploy a Zuul sandbox by using Software Factory. To do so, please read
this `article
<http://www.softwarefactory-project.io/how-to-setup-a-software-factory-sandbox.html>`_,
that explain how to setup a SF sandbox. This article and upcoming ones are based
on a Software Factory deployment, so we highly recommend to deploy this sandbox
to successfully experiment with Zuul.

Zuul project
............
`Zuul <https://docs.openstack.org/infra/zuul/>`_ is a program created by the
OpenStack-infra team to be the gating system for OpenStack project. The main
role of Zuul is to gate projects’s source code. Zuul ensures changes are only
merged if they pass the tests jobs. Zuul jobs are created using ansible
playbooks and roles to perform tests.

The major keys features of Zuul are:
* Smart gating: avoid broken master branch.
* Speculative testing: tests jobs are executed on the future states of projects repositories.
* Scaling: Zuul relies on Nodepool to leverage a pool of test nodes.
* Pipelines: Lifecycle of Pull requests/Gerrit changes is defines though pipelines.
* Multi-repository (Zuul can gate projects spreads accros multiple repositories).
* Parallel testing.
* In repository job configuration: each project can defined its configuration in a .zuul.yaml.
* Pre-merge job loading:Jobs changes are loaded by Zuul and tested before being merged.
* Multi-node job support: Zuul can use execute jobs that need more than on test nodes to execute.
.
All these features will be explained in the following articles.

Zuul components
...............

Zuul is composed of multiple components and work together with Code Review
system. Here is a list of these components:

* Code review system: (gerrit or/and github) contains the reviews or pull
  requests to validate.
* zuul-scheduler receives events from remote systems, Schedules job execution
  according to project's job configuration and reports job results to Code
  Review system.
* zuul-executor uses ansible to execute job remotely on test nodes provided by Nodepool.
* nodepool prepares and deploy slaves used to run tests jobs (OpenStack instances
  or OCI containers could be use in a Software Factory deployment).
* zuul-web is the REST API and the Zuul Web frontend

.. figure:: images/simple_zuul_arch.png
   :width: 80%

You can find a full description of all the components in the `documentation
<https://docs.openstack.org/infra/zuul/admin/components.html>`_.

Zuul in Software Factory
........................

Zuul components are configured using the config repository, the configuration is
on zuul.d. You can clone this repository on your workstation, it will be used in
the next articles to configure Zuul:

.. code-block:: bash

   git clone -c http.sslVerify=false https://sftests.com/r/config

The main configuration files for Zuul are located in */etc/zuul*:
* zuul.conf is the main configuration file for zuul.
* main.yaml contains the tenants, remote systems and repositories.

Each log files for zuul components (scheduler, executor and web) are located in
*/var/log/zuul*.

You can access to Zuul-web on *https://sftests.com/zuul/t/local/status.html* and
on the documentation for your deployement using *https://sftests.com/docs/*.

.. figure:: images/zuul_web.png
   :width: 80%

Stay tuned sor the next article, where we will create a first project in
Software Factory Gerrit and gate a first change via Zuul.
