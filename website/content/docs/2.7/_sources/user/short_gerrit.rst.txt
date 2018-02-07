.. _short-gerrit:

.. note::

  This is a lightweight documentation intended to get users started with Gerrit
  as a code review service. For more insight on what Gerrit can do, please refer
  to its upstream documentation_.

.. _documentation: https://gerrit-review.googlesource.com/Documentation/

Gerrit short user documentation
===============================

Gerrit interface
----------------
Following are some important fields, links and buttons that you need to be aware of.

**Reviewers**
  This field contains the list of reviewers for this patch. Getting into
  this list is as simple as posting a comment on the patch. Reviewers
  can be added by other parties, by default people who have committed changes
  that affect the files in a given patch are automatically added as reviewers.
  The list of approvals given by a reviewer appears near their names.

  Following are the approval types:

  - Verified
      Any score in this means that the patch has been verified by compiling
      and running the test cases. This score is given by a specific user
      called **Jenkins** or **Zuul** (if Zuul3 is activated), by running jobs
      defined in the repository's *check* or *gate* pipelines.

  - Code-Review
      As the name implies, it contains the approvals for code review. Only
      **core-developers** can attribute a score of '+2'.

  - Workflow
      A '+1' score means that this patch is approved for merging. Only
      **core-developers** can attribute a score of '+1'.
      A '0' score means that this patch is ready for review.
      A '-1' score means that this patch is a work in progress.

**Add Reviewer**
  This button enables you to add new reviewers.

**Dependencies**
  This field lists other submitted patches that the current one depends on and that
  are not merged yet. These patches can belong to the same repository (same
  branch or not) or to other repositories (for example a change in a client
  library reflecting a change on the server's API).

**Patch Sets**
  When a patch is committed for the first time, a 'Change-Id' is created. For
  further amendments to the patch, the 'Commit-Id' changes but the 'Change-Id'
  will not. Gerrit groups the patches and their revisions based on this. This
  field lists all the revisions of the current change set and numbers them
  accordingly.

  Each and every patch set contains the list of files and their changes.
  Expand any patch set by clicking the arrow near it.

**Reference Version**
  When the review page is loaded, it expands just the last patch set, and will
  list down the changes that have been made on top of the parent commit
  (Base Version). This is the same with every patch set.

  In order to get the list of changes for say, patch set 11 from patch set 10,
  you need to select patch set 10 from the reference version.

**Changed items**
  When a patch set is expanded, it will list down the changed files. By clicking
  any file in this list will open a comparison page which will compare the
  changes of the selected patch set with the same file in the reference version.

  Upon clicking any line, a text box would be displayed with a 'Save' and 'Discard'
  buttons. 'Save' button saves the comment and maintains it in the databases.
  The comments will not be displayed unless you publish them.

**Abandon Change**
  At times, you might want to scrap an entire patch. The 'Abandon Change'
  button helps you to do that. The abandoned patches are listed separately from
  the 'Open' patch sets.

**Restore Change**
  Any abandoned patch can be restored back using this button. The 'Abandon Change'
  and 'Restore Change' buttons are mutually exclusive.

**Review**
  This is the actual button with which reviewers signal that the patch has been
  reviewed. Through this, you can also publish the list of your comments
  on the changes, give your score and, a cover message for the review.

  'Publish' button just publishes your review information. In addition to
  publishing, 'Publish and Submit' button also submits the change for merging.
  If there are enough scores to approve and if there are no conflicts seen
  while merging, Gerrit will rebase and merge the change on the master branch.


Approval Scoring
................

For any patch, the following scores are required before a patch can be merged on the master
branch.

*Verified*
  At least one '+1' and no '-1'

*Code-Review*
  At least two distinct '+2' (not cumulative) and no negative scoring.

*Workflow*
  At least one '+1'


.. _setup_ssh_keys:

Setting up SSH keys
-------------------

If you already have a key pair, the public key will be listed in your .ssh
directory:

.. code-block:: bash

 $ ls ~/.ssh/*.pub

In that case, you can skip to `Adding public key`_

You can generate a SSH key pair if you don't have one already by
executing the following commands

.. code-block:: bash

 $ ssh-keygen -t rsa -C "your_email@your.domain"
 Generating public/private rsa key pair.
 Enter file in which to save the key (/home/you/.ssh/id_rsa):

Then you will be prompted for an optional passphrase. Your key pair will then
be generated.

.. _`Adding public key`:

Adding a public key
...................

Click on your username in the top right corner of the Gerrit UI,
then choose "Settings". On the left you will see SSH PUBLIC KEYS. Paste your
SSH Public Key (usually the key file ending with the .pub extension) into the
corresponding field.
