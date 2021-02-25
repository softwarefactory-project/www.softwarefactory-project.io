Sprint 2019 Feb 1 to Feb 20 summary
###################################

:date: 2019-02-20 10:00
:modified: 2019-02-20 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

Regarding our contributions to Zuul and Nodepool:

* We proposed a URLTrigger driver to Zuul:
  https://review.openstack.org/#/c/635567/
* We've updated the JWT auth spec with improved security, and started discussion
  about authorization. We've updated the PoC patches and the SF distgit. Because
  the patches are not trivial we're waiting on further feedback from upstream
  before going further (especially with the authZ mechanics)
* We continued working on zuul-runner to enable running Zuul jobs locally.
* We worked on Zuul webtrigger driver:
  https://review.openstack.org/#/q/topic:webtrigger
* We worked on a Zuul AMQP trigger driver:
  https://review.openstack.org/#/q/topic:amqp-trigger

Regarding Software Factory:

* We prepared zuul and nodepool package update for upcoming release with AWS
  driver and some of the tech preview (job hierarchy, urltrigger)
* We fixed managesf usage of the Gerrit rsa key. Now managesf owns its own key.
* We added support for gerrithub on hound and repoxplorer. We also fixed the
  welcome page to support gerrithub.
* We continue to work on the ELK stack upgrade.
