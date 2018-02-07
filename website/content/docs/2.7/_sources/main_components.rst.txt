Main components
===============

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


Continuous Integration, Delivery, and Deployment system
-------------------------------------------------------

`Zuul(V3) <https://docs.openstack.org/infra/zuul/feature/zuulv3/>` is the
service in charge of running tests and managing projects's pipeline such as gate and
post deployment:

* Jobs are written in ansible and stored in repository
* Secrets management system to manage deployment/publishing key
* Simple multi-node jobs description

The service is pre-configured with five pipelines:

* A **check** pipeline, used for preliminary tests on upcoming changes
* A **gate** pipeline, used to make sure an approved change can be merged
* A **post** pipeline, executing jobs right after a change has been merged
* A **release** pipeline, executing jobs after a tag has been pushed on a repository
* A **periodic** pipeline, building jobs at a regular interval, usually daily

When deployed locally, the service is configured with a few roles:

* prepare-workspace: copy project with under review change
* emit-ara-report: generate html logs of ansible play
* validate-host: verify and log information about build host
* upload-logs: upload job logs to a static webserver

A Zuul(V2) service is also available for migration purpose but its usage is
deprecated.

.. image:: imgs/zuul.jpg
   :scale: 50 %


Test instances managemer
------------------------

`Nodepool(V3) <https://docs.openstack.org/infra/nodepool/feature/zuulv3>` is
the service in charge of creating tests environment. It supports 3 types of
drivers to create instances:

* Openstack cloud
* OpenContainer (runC)
* Static node

It is designed to handle the life cycle of work nodes (creation, provision,
assignation and destruction).

A Nodepool(V2) service is also available for migration purpose but its usage
is deprecated.


Issue tracker
-------------

`Storyboard <http://docs.openstack.org/infra/storyboard/>`_ is a cross-project
task tracker. StoryBoard lets you efficiently track your work across a large
number of related projects. Flexible project grouping lets you group together
the projects you're interested in so you can find things quicky and easily.

.. image:: imgs/storyboard.png
   :scale: 50 %

Collaborative tools
-------------------

Software Factory deploys a collection of tools that can ease sharing information
within a team:

* `Etherpad <http://en.wikipedia.org/wiki/Etherpad>`_ where team members can
  edit text documents synchronously to collaborate. This is really handy for instance to
  brainstorm or design drafts together.

.. image:: imgs/etherpad.jpg
   :scale: 50 %

* `Lodgeit <http://www.pocoo.org/projects/lodgeit/>`_ is a pastebin-like tool
  that helps sharing code snippets, error stack traces, anything text-based that
  does not need edition.

.. image:: imgs/paste.jpg
   :scale: 50 %

* `Mumble <https://wiki.mumble.info/wiki/Main_Page>`_ is a lightweight VoIP and
  chat software. Software Factory provides the server out of the box, users have
  to install the mumble client for their respective OSes.

.. TODO Task 568: add Projects metrics description and screenshot (repoxporer)
.. ----------------
..
.. `Repoxplorer <https://github.com/morucci/repoxplorer>`_

.. TODO Task 569: add Log management descriptions and screenshots (Ara, Elk and
..                log server)
.. --------------
.. * ARA
.. * ELK
.. * Log server

.. TODO Task 570: add Platform metrics descriptions and screenshots (influxdb,
..                telegraf and grafana
.. ----------------
.. * Influxdb
.. * Telegraf
.. * Grafana
