.. _config-repo:

The Config repository
---------------------

The config repository is a special project used to configure many Software Factory services.
It is similar to the openstack-infra/project-config repository,
it enables users to submit configuration changes through the code review system.
Once a change has been approved, the config-update job is executed to apply the new configuration.

To make a change in the configuration:

* First clone the repository: git clone https:\/\/<fqdn>/r/config
* Edit the relevant files and commit: git commit
* Submit a change for review: git review
* The configuration will be updated once the change is approved and merged

.. note::

  Files starting by a "_" are default settings and they may be modified by
  an upgrade of Software Factory, thus they **shouldn't be modified manually**.
  Note that the default settings are managed in this role
  `sf-config/ansible/roles/sf-repos/templates <https://softwarefactory-project.io/r/gitweb?p=software-factory/sf-config.git;a=tree;f=ansible/roles/sf-repos/templates/config;hb=HEAD>`_,
  and contributions to improve them are welcome.


.. toctree::
   :maxdepth: 2

   resources_user
   zuul3_user
   nodepool3_user
   gerritbot_user
   gerrit_replication_user
   access_control_user
   gerritlinks_user
   repoxplorer_user
   jenkins_user
   zuul_user
   nodepool_user
