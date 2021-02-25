Sprint 2018 29 Nov to 19 Dec summary
####################################

:date: 2018-12-19 10:00
:modified: 2018-12-19 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

Regarding our contributions to Zuul and Nodepool:

* We've prepared a test of zuul-jobs' upload-to-pypi role using devPI (PyPi staging server standalone pypi deployment). What's left to  do is to add it to upstream's third party CI.
* We've answered comments to the JWT spec for Zuul. We need to clarify what is expected for the JWT's generation (delegated or handled  by Zuul)
* We started discussion about Zuul config introspection, Openshift support and Zookeeper replacement with etcd on zuul-discuss list.
* We updated the openapi definition and added a SwaggerUI component to the web interface.
* We have prepare a working pagure instance based on master to validate the Zuul Pagure driver. The driver has been updated an support  a single project check/gate/post workflow. An update blog post has been published https://www.softwarefactory-project.io/zuul-pagure-driver-update.html

Regarding Software Factory:

* We worked to add RHEL support for Software Factory. The next Software Factory release will support both RHEL and CentOS.
* We released SF version 3.2.
* We worked on integrating Pagure in SF to test the new Zuul driver: packaged missing dependencies and added configuration roles.
* We gathered requirements for distro-jobs using DLRN, rpmreq and zuul.
* We added a resources project switch to deactivate code-search/cgit/repoxplorer indexation by project/repo
