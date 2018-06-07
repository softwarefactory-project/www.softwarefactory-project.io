Zuul architecture - How it works
--------------------------------

We decide to create a serie of blog post to explain how to experiment with Zuul
using Software Factory.

In this first article, we will describe Zuul architecture and the Zuul
integration within Software Factory. We also created a `tutorial
<http://www.softwarefactory-project.io/how-to-setup-a-software-factory-sandbox.html>`_
to explain to users how to quickly setup a sandbox environment to experiment
with Zuul 3.

What is Zuul
............
`Zuul <https://docs.openstack.org/infra/zuul/>`_ is a program develop by the
OpenStack-infra team to gate projects’s source code repositories. Zuul
ensure changes are only merged if they pass integration tests.

Zuul is organised around the concept of pipelines. 3 mains pipelines are used to
land a change in the master branch of a git repository:

* Check: When a review is proposed, the jobs defined in the check pipeline are
  executed to ensure the change doesn't break anything.
* Gate: After validation by core reviewers, the change is validated in the gate
  pipeline and merged in the master branch
* Post: This pipeline is used to do some post merge actions, like publish
  documentation or execute action to deploy the change.

One major feature of Zuul is the ability to do cross project gating. For
example, if my project is define in two repository (my-server and my-client), it
is possible to use the depends-on to 
Zuul components
...............


Zuul architecture
.................

In the next article, we will explain how to create a simple gating system for a
simple project.
