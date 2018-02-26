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

