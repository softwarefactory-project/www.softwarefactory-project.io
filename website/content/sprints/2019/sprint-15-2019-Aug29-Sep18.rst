Sprint 2019 Aug 29 to Sep 18 summary
####################################

:date: 2019-09-23 10:00
:modified: 2019-09-23 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

**Regarding our contributions to Zuul and Nodepool:**

* We worked on reducing the numbers of diskimages in Nodepool
* We wrote a phoronix Zuul jobs to validate the performance of cloud providers
* We added a third-party jobs to validate multinode roles with RHEL 8
* We propose fixes to zuul-jobs to support kubectl connections
* We reviewed the autohold-revamp zuul changes

**Regarding Software Factory:**

* We updated keycloack package to the last 7.0 version
* We enforced gateway configuration on sf.io following goods practices on https://observatory.mozilla.org/
* We improved ansible performances on sf by getting only minimal facts during ansible runs
* We worked on integrating and deploying k1s to provide podman container as test resources
* We refactored sf CI job templates to simplify test management
* Keycloak integration: good progress, we have an open review for an ansible role to deploy the service, configure github as an IdP, use MariaDB as the backend, a custom theme and also automatically fetching SSH keys from github
