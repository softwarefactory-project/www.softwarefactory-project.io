Zuul Hands on - part 3 - Use the Zuul jobs library
--------------------------------------------------

:date: 2018-08-30
:category: blog
:authors: Fabien Boucher

In this article, we will provision a python project with a test suite based
on tox and explain how to use the `zuul-jobs library <>`_ to use
a tox Zuul job maintained by the Zuul users community.

To deploy a Software Factory sandbox please read this `article
<http://www.softwarefactory-project.io/how-to-setup-a-software-factory-sandbox.html>`_.
If you already have a Software Factory 3.1 snapshot then restore it.

Create a demo repo
..................

Follow <http://www.softwarefactory-project.io/zuul-hands-on---part-2---gate-a-first-patch.html#Create-the-demo-repo-repository-on-Gerrit>`_
to create the **demo-repo**.

Provision the demo-repo source code
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

Clone **demo-repo** and provision it with a demo source code.

.. code-block:: bash

  git clone -c http.sslVerify=false https://sftests.com/r/demo-repo
  curl -OL https://www.softwarefactory-project.io/demo-codes/hoz-3-demo-repo.tgz
  cd demo-repo
  tar -xzf ../hoz-4-demo-repo.tgz -C .

Push the code to the **demo-repo** repository. Note that we don't use **git review**
here to bypass the review process of Gerrit. Indeed no CI is configured
for this repository yet.

.. code-block:: bash

  git add -A
  git commit -m"Initialize demo-repo project"
  git push gerrit


Use a zuul-jobs predefined job
..............................

Software Factory bundles a copy of the upstream zuul-jobs library. Source code
can be browsed `here <>`_ and documentation `here <>`_.

The demo-repo source code comes with a tox file so we can benefit from
the tox-py27 zuul job.

.. code-block:: yaml

  - project:
      check:
        jobs:
          - tox-py27
      gate:
        jobs:
          - tox-py27


.. code-block:: bash

  git review -s # Enter admin as username
  git add .zuul.yaml
  git review


Stay tuned for the next article, ...
