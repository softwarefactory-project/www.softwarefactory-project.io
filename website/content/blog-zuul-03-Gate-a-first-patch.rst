Zuul Hands on - part 2 - Gate a first patch
-------------------------------------------

:date: 2018-06-15
:category: blog
:authors: Fabien Boucher

In this article, we will explain how to create a project into a Software Factory
sandbox deployment and configure a basic CI workflow in order to gate a first
patch with Zuul.

You can deploy a Software Factory sandbox to get a ready to use Zuul installation.
To do so, please read this `article
<http://www.softwarefactory-project.io/how-to-setup-a-software-factory-sandbox.html>`_.

Create and initialize a demo project
....................................

To create a Gerrit repository, you need to create a patch into the config
repository of Software Factory. This patch contains a YAML file that describe
the repository to create. A second file is needed to tell Zuul to take in
account this new repository.

First clone the config repository
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

From your host, clone the config repository and configure **git review**:

.. code-block:: bash

  git clone -c http.sslVerify=false https://sftests.com/r/config
  cd config
  git review -s

Create the demo-repo repository on Gerrit
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

Here is the source of the **demo-repo.yaml**:

.. code-block:: yaml

  resources:
    repos:
      demo-repo:
        description: A demo repository
        acl: config-acl

Here is the **zuul-tenant.yaml** configuration file:

.. code-block:: yaml

  - tenant:
      name: local
      source:
        gerrit:
          untrusted-projects:
            - demo-repo

Run **git review** to send the patch on Gerrit:

.. code-block:: bash

  cp /tmp/demo-repo.yaml resources/
  cp /tmp/zuul-tenant.yaml zuul/
  git add -A .
  git commit -m"Add demo repo"
  git review

Two default Zuul jobs are attached to the config repository. The following
workflow applies to patches for this repository.

* A **config-check** job will run to validate incoming patches
* Once a patch is approved with a **+2 Code-Review** and a **+1 Workflow**,
  **config-check** run again and, if succeed, Zuul tells Gerrit to merge it.
* Once merged, a job called **config-update** is executed to apply the new
  configuration to Software Factory.

In other words, Zuul ensures the **Configuration as Code** workflow of
Software Factory.

To finalize the repository creation, connect on the Gerrit interface
on http://sftests.com/r, then find the **Add demo repo** patch. Make sure
**Zuul CI** has voted **+1 Verified**, then set **+2 Code-Review** and
a **+1 Workflow** and wait a couple of minutes to see the **demo-repo**
appears in the Gerrit projects list.

Push the demo-repo source code
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

Here is the file **hello.py** to push in **demo-repo** repository in order
to initialize the project.

.. code-block:: python

  import unittest

  class TestHello(unittest.TestCase):
      def test_hello(self):
          self.assertEqual(hello(), 'Hello Zuul')

  def hello():
      return "Hello Zuul"

  if __name__ == "__main__":
      print(hello())

Push the code to **demo-repo** repository. Note that we don't use **git review**
here to bypass the review process of Gerrit, no CI jobs are configured
yet.

.. code-block:: bash

  git clone -c http.sslVerify=false https://sftests.com/r/demo-repo
  cd demo-repo
  cp /tmp/hello.py .
  git add hello.py
  git commit -m"Initialize demo-repo project"
  git push


Setup a Zuul job for demo-repo
..............................

Now that the **demo-repo** is created and provisionned, let's create a job and
configure its Zuul pipelines.

Create a job Ansible playbook.

In demo-repo, create the file **playbooks/unittests.yaml**:

.. code-block:: yaml

  - hosts: all
    tasks:
      - name: Run unittests
        shell:
          cmd: "sleep 120; python -m unittest -v hello"
          chdir: "{{ zuul.project.src_dir }}"

Define the unittests Zuul job and attached it to Zuul pipelines.

In **demo-repo**, create the file **.zuul.yaml**:

.. code-block:: yaml

  - job:
      name: unittests
      description: Run unittest
      run: playbooks/unittests.yaml

  - project:
      check:
        jobs:
          - unittests
      gate:
        jobs:
          - unittests

Submit those changes, as a patch on Gerrit:

.. code-block:: bash

  git add -A
  git commit -m"Init demo-repo pipelines"
  git review


Zuul gates the patch
....................

Once this patch, that contain a job definition, is submitted to Gerrit, Zuul
receives a notification and will load the proposed job configuration. Thanks
to this new job configration, Zuul will:

- execute the **unittests** job into the **check** pipeline
- execute the **unittests** job into the **gate** pipeline
- call the Gerrit API to merge the patch if the **gate** job succeed

The **unittests** job is simple, it tells Zuul to execute the Ansible
playbook **unittests.yaml**. This playbook contains a single task that will
be run on all nodes of the Ansible inventory. Under the hood Zuul has
created an inventory based on the default **base job** nodeset. The default
**base job** nodeset in Software Factory contains a single test node provided
by the OCI driver of Nodepool.

We can check that Zuul has reported a note in the Verified Label.

.. img:: Screenshot

Software Factory Zuul **base job** runs a post playbook that takes
care of exporting jobs logs to the Software Factory logs server. To access
it, simply click on the job name.

.. img:: Screenshot

In order, to tell Zuul to start to process jobs for the **gate** pipeline,
the patch need to receive the proper approvals, **+2 Code-Review** and a
**+1 Workflow**.

Let's have a look to the Zuul job live console. The **unittests** playbook
should wait for 120 seconds before starting the **python -m unittests** command
so we should have time to see the execution of the job.

.. img:: Screenshot

As soon as the **gate** job finished with success, Zuul has merged the patch
into **demo-repo**. If you reached that point, congratulation, you
succeeded to configure Zuul to gate patches on a new project !

Now, new patches submitted on the **demo-repo** project, will trigger
the CI workflow.

Extra tasks for the curious reader
..................................

* Send a new patch that fails to pass the unittests. Then fix it, by amending
  this same patch.
* Read the default **base job** in the config repository in **zuul.d/_jobs-base.yaml**.
* Read the **pre.yaml** and **post.yaml** playbooks that the **base job** run prior and
  after every jobs.
* Read **zuul.d/_pipelines.yaml** that configure when Zuul must execute jobs and
  in which pipelines.

These files are part of the Zuul integration into Software Factory, they are
self managed but knowing their existance is quite important for mastering
Zuul.

You can still refer to the Zuul documention, here is the local copy
you get with any Software Factory deployment: http://sftests.com/docs/zuul.

To sum up
.........

This blog post should have let you do your first experiments with Zuul.
Stay tuned for the next article, where we will use the Zuul job library
to take advantage of pre-defined Ansible role to ease job creation.
