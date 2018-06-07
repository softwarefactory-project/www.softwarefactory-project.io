Zuul architecture - How it works
--------------------------------

:date: 2018-06-13
:category: blog
:authors: Nicolas Hicher

This article is the first of a series about learning Zuul usage. The serie will
start with quite simple use case to more complex jobs configurations.

In this first article, we will quickly introduce Zuul components used in the
following blog posts.

You can deploy a Zuul sandbox by using Software Factory. To do so, please read
this `article
<http://www.softwarefactory-project.io/how-to-setup-a-software-factory-sandbox.html>`_,
that explain how to setup a SF sandbox. This sandbox environment will be the
base for this serie of articles.

What is Zuul
............
`Zuul <https://docs.openstack.org/infra/zuul/>`_ is a program created by the
OpenStack-infra team. The main role of Zuul is to gate projects’s source code.
Zuul ensures changes are only merged if they pass the integration tests defined by
the users. Zuul jobs are created using ansible playbooks and roles to perform
tests.

The major keys features of Zuul are:
* Gating
* Speculative testing
* Scaling
* Pipelines

All these features will be explained in the following articles.

Zuul components
...............

You can find a full description of all the components on the `documentation
<https://docs.openstack.org/infra/zuul/admin/components.html>`_. The main
components used for these blog articles are:

* remote system: gerrit or/and github which contains the reviews or pull
  requests to validate.
* zuul-scheduler receives events from remote systems, enqueues items into
  pipeline, distributes jobs to zuul-executor and report results to remote
  systems.
* zuul-executor runs jobs on slaves provide by nodepool.
* nodepool prepares and deploy slaves used to run CI jobs (OpenStack instances
  or OCI containers could be use in a Software Factory deployment).
* zuul-web to visualize zuul pipelines, running jobs and queues.

.. figure:: images/simple_zuul_arch.png
   :width: 80%

Zuul in Software Factory
........................

Zuul components are configured using the config repository, we will explain how
to add and configure a projet in the next article.

The main configuration files for Zuul are located in */etc/zuul*:
* zuul.conf with the configuration for all zuul services.
* main.yaml contains the tenants, remote systems and repositories

The log files for zuul components (scheduler, executor) are located in
*/var/log/zuul*.

You can access to Zuul-web on *https://sftests.com/zuul/t/local/status.html* and
on the documentation for your deployement using *https://sftests.com/docs/*.

.. figure:: images/zuul_web.png
   :width: 80%

In the next article, we will explain how to create a simple gating system for a
project.
