Zuul Hands on - part 4 - The gate pipeline
------------------------------------------

:date: 2018-09-03
:category: blog
:authors: Fabien Boucher
:tags: zuul-hands-on-series

In this article, we will explain one of the most important feature of Zuul that
is the dependent pipeline also known as the gate pipeline.

To deploy a Software Factory sandbox please read this `article <{filename}/blog-zuul-01-setup-sandbox.rst>`_.

If you previously created the VM snapshot as recommended at the end of the setting
process of the sandbox then it is adviced to restore it. In that case make sure
the system date of the restored VM is correct. If not fix it by running
*systemctl stop ntpd; ntpd -gq; systemctl start ntpd*.

This article is part of the `Zuul hands-on series <{tag}zuul-hands-on-series>`_.

The broken master phenomenon
............................

Keeping the master branch sane can be difficult when:

- validating a patch for a project takes a long time
- the amount of patches proposals submitted to a project is quite high

Let's take this situation where the project gating is done manually. Between
the moment a core reviewer decides to check a patch **A** and the moment he
accepts it by submitting it to master, another reviewer may have merged another
patch **B**. In that situation, the tip of the master might end up in an
unexpected, undesirable or even broken state because the first reviewer has
just tested master **HEAD** + **A** and not master **HEAD** + **B** + **A**.

Zuul, the gatekeeper
....................

Thanks to its gate pipeline, Zuul decides whether a patch can be merged
into the master branch or not by ensuring the patch is always tested over the
latest version of master prior to merging. This pipeline is designed to Avoid
breaking the master branch. By broken, you need to understand, when unit tests
or functional tests no longer pass on the tip of master.

The gate pipeline takes care of the change rebases  in order
to run CI job(s) on the future state of the project. For instance, once a
change is approved on the Code Review system, Zuul runs the job(s) (the project
test suite) on top of the project master **HEAD** with patch **A** applied on it.
If another patch **B** was being tested for the same project (therefore pending
a merge) prior to the approval of patch **A**, Zuul will run the test suite on
**HEAD** + **B** + **A**. This is called the speculative testing.

Furthermore the gate pipeline ensures that the merging order of patches
is the same than their approval order. If jobs of change **B**, that is on top
of the gate pipeline, are still running when all jobs of the change **A** have
succeeded, then zuul will wait for **B**'s jobs to finish to merge **B**
then **A**.

Finally, the gate pipeline is able to discard broken patches and rebase
following changes in order to optimize testing time. For instance three changes
have entered the gate pipeline:

- HEAD + A
- HEAD + A + B (Failed)
- HEAD + A + B + C (Canceled)
- HEAD + A + C (rebased and restarted)

But a job for **B** failed. Instead of waiting for **C**'s jobs that will
propably fail as **B** introduced an issue then Zuul cancels **C**'s jobs,
rebase **C** on **A** and restart **C**'s jobs. Zuul reports the issue
for **B** on the code review system.


The gate pipeline definition
............................

.. code-block:: yaml


  - pipeline:
      name: gate
      description: |
        Changes that have been approved by core developers are enqueued
        in order in this pipeline, and if they pass tests, will be
        merged.
      success-message: Build succeeded (gate pipeline).
      failure-message: |
        Build failed (gate pipeline).  For information on how to proceed, see
        http://docs.openstack.org/infra/manual/developers.html#automated-testing
      manager: dependent
      precedence: high
      require:
        gerrit:
          open: True
          current-patchset: True
          approval:
            - Verified: [1, 2]
              username: zuul
            - Workflow: 1
      trigger:
        gerrit:
          - event: comment-added
            approval:
              - Workflow: 1
          - event: comment-added
            approval:
              - Verified: 1
            username: zuul
      start:
        gerrit:
          Verified: 0
      success:
        gerrit:
          Verified: 2
          submit: true
        sqlreporter:
      failure:
        gerrit:
          Verified: -2
        sqlreporter:
      window-floor: 20
      window-increase-factor: 2

WIP - explain config here - WIP


Let's test it
.............

We are going to provision a demo project and simulate three changes.

Create and provision the demo repo
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

Follow this section of the `previous article <{filename}/blog-zuul-03-Gate-a-first-patch.rst#create-the-demo-repo-repository-on-gerrit>`_
to create the **demo-repo** and `this section <{filename}/blog-zuul-04-Use-Zuul-jobs.rst>#provision-the-demo-repo-source-code>`_
to provision the demo project.

Setup CI jobs
,,,,,,,,,,,,,

In **.zuul.yaml** define the project's pipelines. We use the special **noop**
job in the check pipeline.

.. code-block:: yaml

  - project:
      check:
        jobs:
          - noop
      gate:
        jobs:
          - tox-py27
          - tox-pep8

And modify the project test **tests/test_hello.py**as follow in order to let us
time to see the dependent pipeline behavior.

.. code-block:: python

  import unittest
  import time

  from hello import hello


  class TestHello(unittest.TestCase):
      def test_hello(self):
          time.sleep(30)
          self.assertEqual(hello.Hello().run(), 'Hello Zuul')


Then submit the change on Gerrit:

.. code-block:: bash

  git add -A
  git commit -m"Init demo-repo pipelines"
  git review

Do not forget to approve the patch to let it land.

Run the scenario
,,,,,,,,,,,,,,,,

WIP WIP

Stay tuned for the next article.
