Sprint 2019 Mar 15 to April 03 summary
######################################

:date: 2019-04-03 10:00
:modified: 2019-04-03 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

Regarding our contributions to Zuul and Nodepool:

* Implemented a Elasticsearch reporter for Zuul https://review.openstack.org/644927/.
* Move forward with the Zuul/Pagure driver https://review.openstack.org/604404/.
* We made good progress on the authentication spec and implementation. We're working on the GUI side, and a demo docker-compose to allow others to play around with the change.
* We continued working on the zuul-runner feature.
* We discussed about Zuul build parameter and implemented a job filter/build button.

Regarding Software Factory:

* We packaged zuul-3.7 with the multi-ansible bundles.
* We investigated how to manage resources update with the supercedent pipeline manager.
* We investigated a zuul-operator.
* Some work on sf-config to handle commit range in managesf resources for config-update and config-check.
* We've made cauth aware of groups. A new "groups" key was added to the authentication cookie. The groups can either be defined in the resources, or mapped from a SAML assertion.
* We worked to improve logstash filtering on SF to use timestamp from logs files instead the one logstash create when it receive message.
* We proposed a submit-logstash role on zuul-jobs to allow users to export jobs' artifacts directly to logstash.
