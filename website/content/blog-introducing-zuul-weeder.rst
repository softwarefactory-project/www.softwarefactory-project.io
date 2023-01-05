Introducing Zuul Weeder
##########################

:date: 2022-05-23 00:00
:category: blog
:authors: tristanC and fboucher

The last month we have been developping a new tool to help us operate `Zuul <https://zuul-ci.org>`_,
and today we are happy to announce the first release of the project.

- Demo deployment `https://sofwarefactory-project.io/weeder <https://softwarefactory-project.io/weeder>`_,
- Source code `software-factory/zuul-weeder <https://github.com/softwarefactory-project/zuul-weeder#readme>`_.

Overview and scope
====================

Zuul Weeder analyzes the configuration objects such as jobs and nodesets and provides a search interface for:

- Depencencies: what depends on an object.
- Requirements: what is needed by an object.
- URL of the configuration files that contains the object.

The goal is to help evaluate the impact of a configuration change.
Zuul Weeder leverage a generic dependency graph using the data found in the ZooKeeper database
to collect every configuration elements used by any tenants.
For example, when removing a node label or a repository.


Usage
======

The service provide two functions:

- */search/$name* returns the list of object matching the requested name.
- */object/$type/$name* returns
  - the list of configuration file url that directly defines or uses the object,
  - the list of related objects that are reachable, either by requirement or by dependency.

For example, by visiting */search/centos*, the service returns:

- job tripleo-centos
- nodeset centos
- label cloud-centos

.. image:: images/zuul-weeder-search.png
   :alt: None

|

And by visiting */object/nodeset/centos*, the service returns:

- The list of zuul.yaml file url that contains a nodeset named *centos*.
- The list of jobs and project that depends on this nodeset.
- The list of node label name that is required by this nodeset.

The results can be scoped to a specific tenant by using the */tenant/$tenant* url prefix.

.. image:: images/zuul-weeder-object.png
   :alt: None
