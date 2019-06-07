Sprint 2019 May 16 to June 05 summary
######################################

:date: 2019-06-07 10:00
:modified: 2019-06-07 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

Regarding our contributions to Zuul and Nodepool:

* We improved the webtrigger interface to support multiple pipeline for different nodeset and detect the default branch.
* We helped fixes issues in Zuul CI for the containers and tox-remote jobs.
* We added tests to the React scripts bump for Zuul.
* We added a cleanup-run phase to Zuul jobs: https://review.opendev.org/#/q/topic:cleanup-phase .
* We improved the Pagure driver tests to add Cross gerrit/github/pagure tests
* We have updated the Elasticsearch Zuul driver to not by default export vars and exported vars

Regarding Software Factory:

* We continued to improve our multi-instances ci job to have a better tests coverage for tenants deployment.
* We prepared SF 3.3 release during the sprint and did a lot of testing around tenants deployment features.
* We upgraded sf-project.io, review.rdoproject.org and ansible.softwarefactory-project.io to SF 3.3 candidate
* We have investigated solution to build SF with distro-jobs on Copr instead of local Mock
* We have investigated further how to replace cauth by Keycloak
