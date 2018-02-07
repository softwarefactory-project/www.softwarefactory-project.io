:orphan:

.. _deepdive:

Internals
=========

The goal of this document is to describe Software Factory's internals.

Organisation
------------

The project is divided into many repositories, available on the
https://softwarefactory-project.io gerrit software-factory/ namespace,
and replicated on github at https://github.com/softwarefactory-project ::

* sf-release: The release rpm to install the repository
* sf-config: The configuration/upgrade process
* sf-docs: The documentation
* sf-ci: The SF testing framework
* sf-elements: Diskimage builder elements
* sfinfo: The rpm distribution informations
* ...

All the components are packaged using **distgit** repositories.


The components
--------------

Below is an overview of all the components integration (shown as dashed boxes) and services
along with their connections to each others.

.. graphviz:: components.dot


The SSO mechanism
-----------------

Below is the sequence diagram of the SSO mechanism.

.. graphviz:: authentication.dot


Ansible usage
-------------

The arch.yaml file describes what roles should run on which instances. Then
based on this information, the sfconfig process generates all the necessary
playbooks to configure and maintain the deployment:

* The **sf_setup.yml** playbook runs the install, setup, config_update tasks to deploy
  the services on a fresh instance.
* The **sf_configrepo_update.yml** playbook applies the config project configuration,
  it is the playbook executed by the *config-update* job.
* The **sf_backup.yml** playbook collects all the services' data in /var/lib/software-factory/backup
* The **get_logs.yml** playbook collects all the services' logs, it's mostly used for sf-ci logs collections.
* The **sf_erase.yml** playbook disables and can remove all the services' data, it is used to un-install the services.


The system configuration
------------------------

The sfconfig script drives the system configuration. This script does the following actions:

* Generates secrets such as internal passwords, ssh keys and tls certificats,

* Ensures configuration files are up-to-date, this script
  checks for missing section and makes sure the defaults value are present. This is particularly
  useful when after an upgrade, a new component configuration has been added

* Generates Ansible inventory and configuration playbook based on the arch.yaml file.

* Generates and execute an Ansible playbook based on the action (e.g. setup, recover, upgrade, ...)

* Waits for ssh access to all instances

* Run testinfra tests

* All the generated data is written in /var/lib/software-factory:

  * ansible/ contains the playbooks and the group_vars.

  * bootstrap-data/ contains file secrets such as tls certificats or ssh keys.

  * sql/ contains database creation scripts.

That system configuration process is re-entrant and needs to be executed everytime the settings are changed.

Then SF is meant to be a self-service system, thus project configuration is done through the config-repo.


The config-repo
---------------

Once SF is up and running, the user configuration of Software Factory happens
via the config-repo:

* zuul3/: Zuul3 configuration
* nodepoolV3/: Nodepool3 configuration
* gerritbot/: IRC notification for gerrit event configuration,
* gerrit/: Gerrit replication endpoint configuration, and
* mirrors/: mirror2swift configuration.
* resources/: Platform wide groups, projects, repositories definitions.
* dashboard/: Custom Gerrit dashboard configuration
* repoxplorer/: RepoXplorer additional definitions (idents, groups, ...)
* policies/: ManageSF API ACLs definition

Deprecated configuration:
* jobs/: Jenkins jobs jjb configuration,
* jobs-zuul/: Zuul-launcher jobs jjb configuration,
* zuul/: CI gating zuul yaml configuration,
* nodepool/: Slave configuration with images and labels definitions,

This is actually managed through SF CI system, thanks to the config-update job.
This job is actually an ansible playbook that will:

* Reload zuul configuration (hot reload without losing in-progress tasks),
* Reload nodepool, gerritbot and gerrit replication, and
* Set mirror2swift configuration for manual or next periodic update.
* Apply resources definitions (create repositories, update groups, ...)
