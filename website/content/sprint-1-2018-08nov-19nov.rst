Sprint 2018 09 Nov to 29 Nov summary
####################################

:date: 2018-11-28 10:00
:modified: 2018-11-28 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

Regarding our contributions to Zuul and Nodepool:

* Progress on the Zuul/pagure driver https://review.openstack.org/#/c/604404/ RFE opened(fixed) for Pagure 5.2
* Nodepool fix when multiple floating IP pools in the tenant https://review.openstack.org/#/c/619525/
* Added the --insecure to zuul-secrets.py https://review.openstack.org/#/c/617281/
* We attended the OpenStack summit in Berlin: https://www.softwarefactory-project.io/openstack-summit-berlin-report.html
* We proposed a roadmap to integrate the Openshift driver in Nodepool.
* We worked on adding authentication support to the Zookeeper service: https://review.openstack.org/619156

Regarding Software Factory:

* We published a blog-post about secrets usage in Zuul jobs https://www.softwarefactory-project.io/zuul-hands-on-part-5-job-secrets.html
* We updated python requirements version packaged in SF for the upcoming 3.2 release
* We validated the 3.2-candidate package set
* We finished to migrate sf-ci jobs to use native centos cloud image. We've got issues in the past with packages installed by dib elements not present on centos, this change will help up to prevent this kind of issues.
* We refactored sf-ci playbooks to remove deprecated include ansible statement. The next step will be to convert sf-ci playbooks to roles. This future change will help use to re-use roles to validate multi tenant sf deployment on sf-ci.
* We added reno-notes and sphinx third party CI tests for zuul-jobs. We also clarified the overall epic - which system to run the jobs on.
