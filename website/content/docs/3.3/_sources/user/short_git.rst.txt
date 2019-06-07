.. _short-git:

.. note::

  This is a lightweight documentation intended to get users started with Git for
  code revision management. For more insight on what Git can do, please refer
  to its documentation_.

.. _documentation: https://git-scm.com/documentation

Short Git introduction
======================

Create a patch
--------------
Before starting to work it is a good practice to create a specific development
branch and work on it. The branch name will be displayed as the topic for the
patch(es) you are going to create on it, so give it a meaningful name like
bug/{bug-id}, title-bug-fix, ...

To create a branch:

.. code-block:: bash

 $ git checkout -b branch-name
 # Switched to a new branch 'branch-name'
 $ git branch
 * branch-name
   master


Make and commit your change
...........................

Edit your local code. At any time, you can see the changes
you made with

.. code-block:: bash

 $ git status
 # On branch branch-name
 # Changes not staged for commit:
 #   (use "git add <file>..." to update what will be committed)
 #   (use "git checkout -- <file>..." to discard changes in working directory)
 #
 #     modified:   modified-file
 #
 # Untracked files:
 #   (use "git add <file>..." to include in what will be committed)
 #
 #     new-file
 no changes added to commit (use "git add" and/or "git commit -a")

You can review the changes you made so far by

.. code-block:: bash

 $ git diff

When you are happy with your changes, you need to add the changes by executing

.. code-block:: bash

 $ git add list/of/files/to/add

After adding the files, you need to commit the changes in your local repo

.. code-block:: bash

 $ git commit -m "Detailed description about the change"


Rebase your change
..................

It's a good idea, but not mandatory, to synchronize your own change
with any changes that may have occurred on master while you've been working.
From within the branch you've been working on, execute the following command:

.. code-block:: bash

 $ git pull --rebase origin master

This command will fetch new commits from the remote master branch and then
rebase your local commit on top of them. It will temporarily set aside the
changes you've made in your branch, apply all of the changes that have happened
in master to your working branch, then merge (recommit) all of the changes you've made
back into the branch. Doing this will help avoid future merge conflicts. Plus, it gives
you an opportunity to test your changes against the latest code in master.


Amending a change
.................

Sometimes, you might need to amend a submitted change, for instance to acknowledge
improvement suggestions or because your change failed in the CI pipelines. Then
you need to amend your change. You can amend your own
changes as well as changes submitted by someone else, as long as the change
hasn't been merged yet.

You can check the change out in your local copy of the repository like this:

.. code-block:: bash

 git review -d {change number}

.. note::

  if you already have the change in a branch on your local repository,
  you can just check it out instead:

.. code-block:: bash

 git checkout {branch-name}

After adding the necessary changes, amend the existing commit like this

.. code-block:: bash

 git commit --amend

.. warning::

  DO NOT use the -m flag to specify a commit summary: that will
  override the previous summary and regenerate the Change-Id. Instead, use
  your text editor to change the commit summary if needed, and keep
  the Change-Id line intact.

Now, push the change using ``git review``.
