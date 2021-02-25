Sprint 2019 June 06 to June 26 summary
######################################

:date: 2019-06-28 10:00
:modified: 2019-06-28 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

**Regarding our contributions to Zuul and Nodepool:**

* We have got the Pagure driver merged in Zuul
* We fixed Zuul to be able to display a start-message on gerrit that redirect to the buildset status page (`see the change in opendev <https://review.opendev.org/#/q/topic:start-message>`_)
* After merging the JWT spec, we worked on addressing comments on the implementation (missing doc and release notes). We're waiting on more validation.
* We started discussion on the mailing list about upgrading ara to 1.0

**Regarding Software Factory:**

* We addressed the dependency issues with installation of some components on RHEL 7 (mock and python-daemon). We added check on sfconfig and provided user documentation for it (see `change 15759 <https://softwarefactory-project.io/r/#/c/15759/>`_ and `change 15751 <https://softwarefactory-project.io/r/#/c/15751/>`_ in SF Gerrit)

* We've added managesf nodepool endpoint and now integrating this endpoint on the config check job
* We are working on making managesf py3x only. We've pruned a lot of dead code and are currently working on porting the code and tests to Python 3x.
