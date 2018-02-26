==================
User documentation
==================

This chapter documents how to use Software Factory.

CI/CD overview
--------------

The diagram below shows an overview of how Continous Integration/Continuous Deployment
happens on Software Factory:

.. graphviz:: test_workflow.dot


Create and configure a new project
----------------------------------

Creating a new project or repository is done by submitting a change on the
:ref:`Config repository <config-repo>`. This repository is a regular project,
see the :ref:`next chapter <contribute>` about how to contribute to a project.

To create and/or configure a project, you need to create a new review on the config
repository. The change consists of two parts:

 * Create the git repository/ies and ACL(s), see :ref:`this example<project-example>`
 * Add the project to the CI system, see :ref:`Zuul main.yaml<zuul-main-yaml>`.

In short, in a single change, the following files need to be created:

 * resources/new-project.yaml
 * zuul/new-project.yaml

Once the change is approved and merged, the project will be created/updated by
the config-update job.


.. _contribute:

Contribute to a project on SF
-----------------------------

Clone a project
...............

Softwarefactory uses `the GIT protocol <http://en.wikipedia.org/wiki/Git_%28software%29>`_
as its revision control system. When a project is created, Gerrit
initializes the project's repository/ies.

Repositories can be `cloned <http://git-scm.com/docs/git-clone>`_ from
the Gerrit server to a local directory. Gerrit allows multiple ways to clone
a project repository.

Using HTTP
''''''''''

.. code-block:: bash

 $ git clone https://{fqdn}/r/{project-name}

Using SSH
'''''''''

Before accessing the SSH URI, one needs to register the SSH public key of
its user. (See :ref:`setup_ssh_keys`)

.. note::

  A user needs to setup SSH public keys in order to create new review.

.. code-block:: bash

 $ git clone ssh://{user-name}@{fqdn}/{project-name}


Create a patch
..............

Once the project is cloned, create a new patch. See this
:ref:`short introduction to git<short-git>`, or the
`git user-manual <https://git-scm.com/docs/user-manual.html>`_, or this
`git from the bottom up <https://jwiegley.github.io/git-from-the-bottom-up/>`_.


Commit message hooks
''''''''''''''''''''

If you are working on a feature or a bug that is defined in a task on the issue tracker,
you can add a line like "Task: XXX" in your commit message, where XXX is the
task number. This way, when you submit your change for review, the
task will see its status updated to "In Progress"; when the change is merged
the task will be closed automatically.
The following keywords are supported:

* Task
* Story
* Related-Task (this will not close the bug upon merging the patch)
* Related-Story (this will not close the bug upon merging the patch)


Create a new Code Review
........................

Before your changes can be merged into master, they must undergo review in Gerrit,
this is call a Code Review, (which is similar to Github Pull Request).

First install git-review. Generally, the easiest way to get the latest version is
to install it using the Python package installer pip. It might also be packaged
for your OS.

.. code-block:: bash

 $ pip install --user git-review


Make sure your SSH public key is setup, see :ref:`setup_ssh_keys`. Then
to push the change to Gerrit, execute the following command:

.. code-block:: bash

 $ git review
 # remote: Processing changes: new: 1, refs: 1, done
 # remote:
 # remote: New Changes:
 # remote:   http://{fqdn}/{change-number}
 # remote:
 # To ssh://{user-name}@{fqdn}:29418/{project-name}
 #  * [new branch]      HEAD -> refs/publish/master/branch-name


.. note::

   The first time you run git review, it will create a new 'gerrit' remote.
   If the project was cloned anonymously from http, it will ask for your
   gerrit username. You can force this process by using: "git review -s"


Review workflow
---------------

Software Factory requires every patch to be reviewed before they are merged.


Who can review
..............

Anybody who is authenticated on Software Factory is eligible to review a patch
of any project except for private projects. Private projects can be
reviewed only by the team leads, developers, and core developers of that
project.

Only the core member as defined in a project ACL can approve (vote +2) a review.


How to review
.............

Ensure you are logged in to Software Factory's web interface and select the patch
you want to review from the list of open patches. See this
:ref:`short introduction to gerrit<short-gerrit>`, or the
`gerrit user-manual <https://gerrit-review.googlesource.com/Documentation/intro-user.html>`_.

Core-reviewer can approve a review by clicking "reply" and:

* Set Code-Review to +2
* Set Workflow to +1

By default, the CI system will:

* Start check jobs when a change is created, it will vote Verify +1 on success.
* Start gate jobs when a change has Verify +1, at least one CR+2 and one W+1.
  it will vote Verify +2 on success
* Merge the change if it has: Verify +2, at least one CR+2 and no W-1.

A comment message including "recheck" will retrigger CI jobs.



Other useful resources
----------------------

* :ref:`The config repository (config-project) <config-repo>`
* `sfmanager </docs/sfmanager/>`_ is a command line client can be used to interact with the managesf API.

.. toctree::
   :maxdepth: 1

   short_git
   short_gerrit
