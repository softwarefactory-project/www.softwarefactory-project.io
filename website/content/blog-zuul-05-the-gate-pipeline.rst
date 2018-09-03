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
to create the **demo-repo** and `this section <{filename}/blog-zuul-04-Use-Zuul-jobs.rst#provision-the-demo-repo-source-code>`_
to provision the demo project.

Setup CI jobs
,,,,,,,,,,,,,

In **.zuul.yaml** define the project's pipelines. We use the special **noop**
job for the check pipeline to force Zuul to return a positive CI note
**+1 Verified**.

.. code-block:: yaml

  - project:
      check:
        jobs:
          - noop
      gate:
        jobs:
          - tox-py27

We also add an helper script **trigger.sh** in order to better highlight the
pipeline behavior, in the status page, by adding some delay according to the
change context.

.. code-block:: bash

  #!/bin/bash

  if [ -f c3 ]; then
      sleep 20
      exit 0
  fi
  if [ -f c2 ]; then
      exit 0
  fi
  if [ -f c1 ]; then
      sleep 90
      exit 0
  fi

And run this command prior to the unittests via tox. Modify as below
to **tox.ini**.

.. code-block:: ini

  [tox]
  envlist = pep8,py27

  [testenv]
  whitelist_externals = *
  deps = nose
  commands =
    ./trigger.sh
    nosetests -v

  [testenv:pep8]
  deps = flake8
  commands = flake8

Finally, submit the change on Gerrit:

.. code-block:: bash

  chmod +x trigger.sh
  git add -A .
  git commit -m"Init demo-repo pipelines"
  git review

Do not forget to approve the patch to let it land.

Run the scenario
,,,,,,,,,,,,,,,,

In this scenario we propose three changes. The second change simulates
the situation where the unittest pass when based on the tips of the master
but fails when rebased on the first change.

Patches are available in `this archive <{filename}/demo-codes/hoz-4-patches.tgz>`_.

.. code-block:: bash

  # Reset local copy to the base commit
  git reset --hard $(git log --pretty=oneline | grep "Init demo-repo pipelines" | awk {'print $1'})
  # Propose first patch (A) that change the returned value the run method
  git am ../0001-Change-run-payload.patch && git review -i

  # Reset local copy to the base commit
  git reset --hard $(git log --pretty=oneline | grep "Init demo-repo pipelines" | awk {'print $1'})
  # Add the second patch (B) that add a test to verify the length of the string
  # returned by the run method does is not greater to 10
  git am ../0001-Add-payload-size-test.patch && git review -i

  # Reset local copy to the base commi
  git reset --hard $(git log --pretty=oneline | grep "Init demo-repo pipelines" | awk {'print $1'})
  # Add the third patch (C) that only add the README.md file to the project
  git am ../0001-Add-project-readme-file.patch && git review -i


In the gate pipeline, prior to the merge, Zuul will tests changes speculatively.
Let's approve all of them in right order.

.. code-block:: bash

  cmsgs=("Change run payload" "Add payload size test" "Add project readme file"); for msg in $cmsgs; do rn=$(python -c "import sys,json,requests;from requests.packages.urllib3.exceptions import InsecureRequestWarning;requests.packages.urllib3.disable_warnings(InsecureRequestWarning);changes=json.loads(requests.get('https://sftests.com/r/changes/', verify=False).text[5:]); m=[c for c in changes if c['subject'] == sys.argv[1]][0]; print m['_number']" $msg); echo "Set change approval (CR+2 and W+1) on change $rn,1"; ssh -p 29418 admin@sftests.com gerrit review $rn,1 --code-review +2 --workflow +1; done


Then have a look to the `Zuul status page <https://sftests.com/zuul/t/local/status.html>`_.

.. image:: images/zuul-hands-on-part4-sc1.png

|

You show see that Zuul have cancelled the current job of B,
in order to rebase it on the A as B introduces an issue when rebased
on A. Zuul won't merge B but report the failure on the Code review, A and C
will be merged.

.. image:: images/zuul-hands-on-part4-sc2.png

|

.. image:: images/zuul-hands-on-part4-sc3.png

|

Let's have a look to the Zuul scheduler logs */var/log/zuul/scheduler.log*:

.. code-block:: raw

  # the executor is told to start the tox-py27 job for change 25 (rebased on 24)
  2018-09-04 10:25:44,795 INFO zuul.ExecutorClient: Execute job tox-py27 (uuid: 93dd828f3e62481e88f329f2eeed2608) on nodes <NodeSet OrderedDict([(('container',), <Node 0000000030 ('container',):runc-centos>)])OrderedDict()> for change <Change 0x7f53140ffd30 25,1> with dependent changes [{'change': '24', 'branch': 'master', 'change_url': 'https://sftests.com/r/24', 'project': {'short_name': 'demo-repo', 'canonical_hostname': 'sftests.com', 'canonical_name': 'sftests.com/demo-repo', 'src_dir': 'src/sftests.com/demo-repo', 'name': 'demo-repo'}, 'patchset': '1'}, {'change': '25', 'branch': 'master', 'change_url': 'https://sftests.com/r/25', 'project': {'short_name': 'demo-repo', 'canonical_hostname': 'sftests.com', 'canonical_name': 'sftests.com/demo-repo', 'src_dir': 'src/sftests.com/demo-repo', 'name': 'demo-repo'}, 'patchset': '1'}]
  # job started
  2018-09-04 10:25:50,533 INFO zuul.ExecutorClient: Build <gear.Job 0x7f5314138080 handle: b'H:10.0.2.15:17' name: executor:execute unique: 93dd828f3e62481e88f329f2eeed2608> started
  ...
  # the executor process reports the issue to the scheduler
  2018-09-04 10:27:25,748 INFO zuul.ExecutorClient: Build <gear.Job 0x7f5314138080 handle: b'H:10.0.2.15:17' name: executor:execute unique: 93dd828f3e62481e88f329f2eeed2608> complete, result FAILURE
  # the scheduler detects the nearest change in the queue is a failure so 26 is rebased on 24
  2018-09-04 10:27:25,769 INFO zuul.Pipeline.local.gate: Resetting builds for change <Change 0x7f5319341e10 26,1> because the item ahead, <QueueItem 0x7f5318208400 for <Change 0x7f53140ffd30 25,1> in gate>, is not the nearest non-failing item, <QueueItem 0x7f53140934a8 for <Change 0x7f5314096390 24,1> in gate>
  ...
  # restart the tox-py27 with the updated context
  2018-09-04 10:27:35,513 INFO zuul.ExecutorClient: Execute job tox-py27 (uuid: adfe76dd347e4b0fba56395a319ac67a) on nodes <NodeSet OrderedDict([(('container',), <Node 0000000033 ('container',):runc-centos>)])OrderedDict()> for change <Change 0x7f5319341e10 26,1> with dependent changes [{'change': '24', 'branch': 'master', 'change_url': 'https://sftests.com/r/24', 'project': {'short_name': 'demo-repo', 'canonical_hostname': 'sftests.com', 'canonical_name': 'sftests.com/demo-repo', 'src_dir': 'src/sftests.com/demo-repo', 'name': 'demo-repo'}, 'patchset': '1'}, {'change': '26', 'branch': 'master', 'change_url': 'https://sftests.com/r/26', 'project': {'short_name': 'demo-repo', 'canonical_hostname': 'sftests.com', 'canonical_name': 'sftests.com/demo-repo', 'src_dir': 'src/sftests.com/demo-repo', 'name': 'demo-repo'}, 'patchset': '1'}]


Stay tuned for the next article.
