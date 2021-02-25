Sprint 2019 Apr 25 to May 15 summary
######################################

:date: 2019-05-17 10:00
:modified: 2019-05-17 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

Regarding our contributions to Zuul and Nodepool:

* We continued working on the webtrigger interface
* We have fixed an issue with dequeue-ref https://review.opendev.org/659110/
* We started the dicussion about the roadmap

Regarding Software Factory:

* We worked on removing the last few Zuul and Nodepool patches.
* We wrote a patch in sf-config to add the support the pagure driver of Zuul https://softwarefactory-project.io/r/15442/
* We created a multinode job to validate multitenants deployment job using sf-ci roles  https://softwarefactory-project.io/r/#/c/15558/
* We have started the release process for SF 3.3, some patches should be merged before we can finalize the release https://softwarefactory-project.io/etherpad/p/sf_3.3_release . We also used the new roles in sf-ci to validate upgrade from 3.2 to 3.3.
* We're experimenting with keycloak as a replacement for cauth.
* We helped tripleo-ci investigate a zuul-runner based reproducer: https://pagure.io/zuul-rdo-reproducer/blob/master/f/run.sh
