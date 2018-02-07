About
#####

:date: 2018-02-07 19:30
:modified: 2018-02-07 19:30
:tags: SoftwareFactory
:slug: about
:authors: Fabien Boucher

Software Factory (also called SF) is a software development forge. It’s optimized to use an OpenStack-based
cloud for resources, but this is not mandatory at all. Setting up a full software development stack manually
can really be time-consuming. Software Factory provides an easy way to get everything you need to host, design,
modify, test and build software; all of this pre-configured and usable immediately. Software Factory feature also
features automated upgrades, so you don’t have to worry about upgrading each services yourself.

Integrated services
-------------------

Software Factory integrates services covering each step in the software production chain:

* Version control and code hosting (Gerrit)
* Code review system (Gerrit)
* CI (Zuul)
* Test instances management (Nodepool)
* Task tracker (Storyboard)
* Collaborative tools (Etherpard, Pastie)
* Repositories metrics (RepoXplorer)
* Log management (ELK)
* System metrics (InfluxDB and Grafana)

Software Factory offers a seamless user experience with:

* Single Sign-On authentication, on every authenticated service
* A unified REST API,
* A top menu to access all the services quickly, and
* A command line tool and a web interface.

To learn more about the service read the `components documentation`_.

.. _`components documentation`: https://softwarefactory-project.io/docs/main_components.html
