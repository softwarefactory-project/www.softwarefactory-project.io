Zuul architecture - How it works
--------------------------------

The Software Factory team decides to create a serie of blog post to explain how
to experiment with Zuul using Software Factory.

In this first article, we will quickly describe Zuul components used in the
following blog posts. We created a `tutorial
<http://www.softwarefactory-project.io/how-to-setup-a-software-factory-sandbox.html>`_
to explain how to quickly setup a sandbox environment to experiment with the
last version of Zuul.

What is Zuul
............
`Zuul <https://docs.openstack.org/infra/zuul/>`_ is a program created by the
OpenStack-infra team. The main role of Zuul is to gate projects’s source code.
Zuul ensure changes are only merged if they pass the integration tests define by
the users. Zuul jobs are created using ansible playbooks and roles to perform
tests.

Zuul is organised around the concept of pipelines. 3 mains pipelines are used to
land a change in the master branch of a git repository:

* Check: When a review is proposed, the jobs defined in the check pipeline are
  executed to ensure the change doesn't break anything.
* Gate: After validation by core reviewers, the change is validated in the gate
  pipeline and merged in the master branch
* Post: This pipeline is used to do some post merge actions, like publish
  documentation or execute action to deploy the change.

These are default pipelines but users can create pipelines for their needs.

Zuul allows cross project testing and cross projet dependencies. For example, if
you have two projects, my-server and my-client, you can use the depends-on
feature to develop the client with a dependancy on a review where a new feature
is developped on the server project. It's a very powerful feature.

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
* zuul-executor runs jobs on slaves provide by nodepool. The executor contains a
  merger to prepare the git repositories used by the jobs (a zuul-merger
  service could also be deployed for a larger deployments).
* nodepool prepares and deploy slaves used to run CI jobs (OpenStack instances
  or OCI containers could be use in a Software Factory deployment).

In the next article, we will explain how to create a simple gating system for a
project.
