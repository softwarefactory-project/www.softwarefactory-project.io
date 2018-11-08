Sprint 2018 19 Oct to 8 Nov summary
###################################

:date: 2018-11-08 10:00
:modified: 2018-11-08 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.


Regarding Software Factory:

* We updated zuul, nodepool packages and their dependencies to the latest release versions.
* We worked on a new Hands On Zuul blog post about using Secrets in jobs https://softwarefactory-project.io/logs/78/14178/1/check/build-pages/1089650/pages/zuul-hands-on-part-5-job-secrets.html
* We worked on a preprod environment to validate the next SF 3.2 release upgrade (4 nodes with an external SF tenant with a dedicated gerrit)
* We are working to use vanilla CentOS image to run sf ci jobs
* We have refactored and re-enabled our CI test for ELK - previous tests were not stable enough
* We merged the username collision strategy handling. Operators can now decide whether to deny or differentiate users from different IdPs with the same username.
* We started work on adding a SSH key to manageSF, in order to expose SSH-related features in the API.

Regarding our contributions to Zuul and Nodepool:

* We worked on a Zuul's Pagure driver WIP - Some new RFE opened on Pagure https://review.openstack.org/#/c/604404/
* We updated the JWT spec. It should be reviewed after the Berlin summit
* We submitted talks to CentOS Dojo, FOSDEM19
* We sorted zuul-jobs per "value" to us as consumers, next sprint we will start adding testing of these selected jobs as a 3rd party CI for upstream.
* We merged the kubernetes driver in Nodepool.
* We fixed small issues with the new Zuul React web interface.
