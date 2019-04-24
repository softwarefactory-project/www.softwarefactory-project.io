Sprint 2019 Apr 04 to April 24 summary
######################################

:date: 2019-04-24 10:00
:modified: 2019-04-24 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

Regarding our contributions to Zuul and Nodepool:

* We proposed a Docker compose PoC upstream so that people can test out the authN/Z feature. A video was shared on the zuul-discuss ML. https://softwarefactory-project.io/static/zuul_jwt_demo.mkv
* We continued the work on the zuul-operator: added rdms and auto-scalling for executor and merger. To improve that implementation, we proposed a  new Ansible module: https://github.com/ansible/ansible/pull/55029
* We added allowed-label restriction to the zuul API: https://review.opendev.org/653895
* Finalized the Zuul/Pagure driver https://review.opendev.org/604404/

Regarding Software Factory:

* We investigated a sf-operator to deploy gerrit and re-use the zuul-operator by re-using the sfconfig and arch file as the custom resource spec to simplify the migration process.
* We updated the etherpad, disk-image-builder, and zuul version to include a security fix: https://www.softwarefactory-project.io/software-factory-32-new-zuul-update-for-security-fix.html
* We simplified the purge-logs script. The previous version was unable some king of periodic jobs logs.
* We added the local tenant with dedicated SF config repository feature in SF
* We converted all playbooks we use in sf-ci in ansible roles. The next step is to create multinodes/multitenants ci jobs, it will be easier with roles.
* We enforced sshd configuration for ci instances following ssh guidelines https://infosec.mozilla.org/guidelines/openssh
* We merged the changes to cauth and sf-config allowing the creation of a JWT for zuul with groups info.
