Zuul Hands on - part 1 - What is Zuul ?
---------------------------------------

:date: 2018-08-08
:category: blog
:authors: Nicolas Hicher
:tags: zuul-hands-on-series

This article is the first in a series about learning Zuul by usage. This series
will start with simple use cases then will cover more complex jobs
configurations.

In this first article, we will quickly introduce Zuul's components and give some
details about how Zuul is integrated within Software Factory.

You can deploy a Zuul sandbox by using Software Factory. To do so, please read
this `article
<http://www.softwarefactory-project.io/how-to-setup-a-software-factory-sandbox.html>`_,
that explains how to setup a SF sandbox. This article and upcoming ones are based
on a Software Factory deployment, so we highly recommend to deploy this sandbox
to successfully experiment with Zuul.

This article is part of the `Zuul hands-on series<{tag}zuul-hands-on-series>`_.

Zuul project
............
`Zuul <https://docs.openstack.org/infra/zuul/>`_ is an application created by
OpenStack's Infra team to be the gating system for OpenStack projects. The main
role of Zuul is to gate all of OpenStack projects’ source code. Zuul ensures
changes are merged on their respective git repositories only if they pass
predefined tests jobs. Zuul jobs consist of a combination of Ansible playbooks and
roles.

You can see live instances of Zuul at the following URLs:

* `OpenStack CI <https://zuul.openstack.org>`_
* `Software Factory <https://softwarefactory-project.io/zuul/>`_
* `RDO CI <https://review.rdoproject.org/zuul/status.html>`_

The key features of Zuul are:

* Gating on git branches: Zuul guarantees that no merged patch will break the code (as covered by testing, of course).
* Speculative testing: tests jobs are executed on the expected states of repositories at merging time.
  This is particularly useful when several, potentially conflicting patches are landing roughly at the same time.
* Scaling: Zuul relies on Nodepool to leverage a pool of test nodes. This can be controlled with quotas on spawning test nodes.
* Pipelines: the lifecycle of Pull Requests/Gerrit changes is defined through pipelines.
* Multi-repository: Zuul can gate projects spread across multiple repositories.
  It is even possible to test changes depending on patches that aren't merged yet in other repositories,
  as Zuul can prepare testing environments that respect code dependencies.
* Parallel testing: Zuul can provision as many jobs as there are nodes available to run them.
* In-repository job configuration: each project can define its pipelines and jobs configuration in a file called .zuul.yaml.
* Pre-merge job loading: modifications to jobs definitions in the .zuul.yaml file
  are loaded by Zuul and can be tested before being merged.
* Multi-node job support: Zuul can run jobs on complex topologies, for example when testing clients and servers.
* Ansible support: test jobs can be run outside of Zuul; and Zuul also comes with the ARA reporting tool to browse through playbooks outputs.

All these features will be explained in more depth in following articles.

Zuul's components
.................

Zuul consists of multiple components that react to events coming from a Code Review
system. Here is a list of these components:

* The **code review (CR) system** hosts the changes to gate with Zuul. Zuul supports Gerrit (code reviews) and Github (Pull Requests).
* **zuul-scheduler** receives events from remote CR systems, and schedules the execution of jobs
  according to a project's job configuration; then reports job results to the CR system.
* **zuul-executor** uses Ansible to execute jobs remotely on test nodes provided by Nodepool.
* **Nodepool** launches, provisions and ultimately destroy nodes needed to run tests jobs (OpenStack instances
  or OCI containers can be used in a Software Factory deployment).
* **zuul-web** is Zuul's Web frontend and provides a REST API.

.. figure:: images/simple_zuul_arch.png
   :width: 80%

You can find a full description of all the components in the `documentation
<https://docs.openstack.org/infra/zuul/admin/components.html>`_.

Zuul in Software Factory
........................

Zuul's components are configured using the *config* repository, the configuration is
in the *zuul.d* directory within that repository. You can clone this repository on your workstation, it will be used in
the next articles to configure Zuul:

.. code-block:: bash

   git clone -c http.sslVerify=false https://sftests.com/r/config

Assuming Software Factory has been deployed on a single server (all-in-one architecture),
the main configuration files for Zuul are located in */etc/zuul*:

* zuul.conf is the main configuration file for zuul.
* main.yaml contains the tenants, remote systems and repositories.

These files are managed with the *sfconfig* utility script, and should not be
edited manually!

The log files for zuul components (scheduler, executor and web) are located in
*/var/log/zuul*.

On your SF deployment, you can access Zuul-web at `<https://sftests.com/zuul/t/local/status.html>`_ and
the documentation at `<https://sftests.com/docs/>`_.

.. figure:: images/zuul_web.png
   :width: 80%

Stay tuned for the next article, where we will create our first project in
Software Factory, and gate a first change via Gerrit and Zuul.
