.. _backup_restore:

Backup restore
==============

Software Factory provides an Ansible playbook *sf_backup* that aims to retrieve
services data into a single directory on the install-server:
*/var/lib/software-factory/backup*. Then this directory can be extracted onto
a backup server (using rsync for example).

The *sfconfig* command provides a *recover* method that setup a
Software Factory with the backed up data from */var/lib/software-factory/backup*.

Create a backup
---------------

To run the backup playbook, from the install-server use the following command:

.. code-block:: bash

  # ansible-playbook /var/lib/software-factory/ansible/sf_backup.yml

.. note:: The sf-ops https://softwarefactory-project.io/r/software-factory/sf-ops
   repository from the Software Factory project provides a backup playbook that will
   fetch the backup directory from a Software Factory instance and store it
   locally.

Recover a backup
----------------

On a fresh deployment, *recover* will deploy the backup and run the Software Factory
setup tasks.

Before running that command, on the install-server node:

 - Install the sf-release package (same version than your previous deployment)
 - Install the sf-config package
 - Copy the backup data into the */var/lib/software-factory/backup* directory
 - Verify that the arch in */etc/software-factory/arch.yml* is as expected for
   your deployment. You can compare to the legacy arch.yml file from
   */var/lib/software-factory/backup/install-server/etc/software-factory/arch.yaml*

The recover will run:

 - install tasks
 - data restoring tasks
 - setup tasks
 - validation tasks

.. code-block:: bash

  # sfconfig --recover
