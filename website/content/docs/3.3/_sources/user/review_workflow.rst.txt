.. _review_workflow:


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

