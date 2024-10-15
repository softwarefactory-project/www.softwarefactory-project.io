.. _gerrit_components:

Code review system
------------------

`Gerrit <http://en.wikipedia.org/wiki/Gerrit_%28software%29>`_ is one of the core
components of Software Factory. It provides the Git repository hosting server,
a code review mechanism, and a powerful ACL system. Within Software Factory Gerrit
is tightly integrated with the issue tracker and the CI pipelines manager.

Some useful plugins are installed on Gerrit:

* Reviewer-by-blame: Automatically adds code reviewers to submitted changes if they
  authored or modified files affected by the changes.
* Replication: Allows the replication of Git repositories hosted on Software
  Factory on a remote location, for example Github.
* Gravatar: Displays the gravatar picture associated with a contributor's email.
* Delete-project: Allow a privileged user to fully remove an useless Gerrit project.
* Download-commands: Allows IDE integration

The following hooks are installed to update the issue tracker on specific events:

* An issue referenced in the commit message of a new submission will be automatically
  set as "In progress" in the issue tracker.
* An issue referenced by a submission will be closed when the patch gets merged into the main repository.

The following events will trigger actions on the CI pipelines:

* A new patch being submitted, or modified
* A "recheck" or "retrigger" message in the patch's comments
* A patch reaching the score needed to be candidate for merging (+2 Core, +1 Workflow, +1 Verified)
* A patch being merged

See the `pipelines manager <Pipelines manager>`_ section for more details.

.. image:: imgs/gerrit.jpg
   :scale: 50 %
