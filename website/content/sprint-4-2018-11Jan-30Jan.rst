Sprint 2019 11 Jan to 30 Jan summary
####################################

:date: 2019-01-30 10:00
:modified: 2019-01-30 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

Regarding our contributions to Zuul and Nodepool:

* freeze_job: worked on a new zuul-runner command line to be able to run a job locally.
  This rebased and fix the proposed implementation and added the execute sub-command
  as well as support for depends-on: https://review.openstack.org/#/q/topic:freeze_job.
* parameterized build: started the discussion to be able to run job from the web interface.
* zuul-web: worked on new interfaces to display job's hierarchy, build roles and config.
* zuul-jobs: we proposed a series of guidelines to write jobs, so that multiple environments
  (OS flavors, privileges) can be supported http://logs.openstack.org/07/631507/3/check/tox-docs/971c8fd/html/policy.html#coding-guidelines.
* zuul-jobs: we proposed a change to allow running nodejs zuul-jobs on RPM based systems.
* zuul/pagure driver: proposed two changes (new REST enpoints) on Pagure to ease Zuul
  integration https://pagure.io/pagure/pull-request/4221 and https://pagure.io/pagure/pull-request/4223.

Regarding Software Factory:

* blog: proposed a new one about SF/Zuul/Nodepool workflows: https://softwarefactory-project.io/r/#/c/14874/.
* zuul/nodepool: updated the distgit for a security issue, backport to 3.2 and updated the services.
* cauth: improved the logging to include transaction id.
* started the work on supporting python3 for the rest of the services (cauth, managesf, gerritbot, ...).
