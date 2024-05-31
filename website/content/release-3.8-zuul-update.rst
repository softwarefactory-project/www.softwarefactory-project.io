Software Factory 3.8 Zuul/Nodepool Update
#########################################

:date: 2024-05-02 00:00
:category: blog
:authors: fbo

Software Factory 3.8 is featured with Zuul and Nodepool 8.1 and as of today we have not scheduled to
release a new official Software Factory version as our goal is to migrate to an OpenShift based deployment
through the `sf-operator <https://github.com/softwarefactory-project/sf-operator>`_ project.

However to mitigate the delay to migrate our production to the sf-operator we are providing a solution
to enable Zuul 10.0.0 and Nodepool 10.0.0 with the current Software Factory 3.8.

Assuming the Software Factory deployment is running the version 3.8 (sf-config-3.8.8-4), we can follow
the process below.

.. note::

  Make sure to have a minimum of 10GB disk space available on all the hosts part of your SF infra to perform the update.

.. code-block:: bash

  # Backup your Software Factory data
  ansible-playbook /var/lib/software-factory/ansible/sf_backup.yml

  # Install this specific sf-config package
  yum install sf-config-3.8.9-4

  # Ensure to deactivate the automatic restart of Zuul and Nodepool
  echo "disable_zuul_autorestart: true" >> /etc/software-factory/custom-vars.yaml
  echo "disable_nodepool_autorestart: true" >> /etc/software-factory/custom-vars.yaml

  # Stop all Zuul/Nodepool services (adapt the command if services are running on multiple nodes)
  systemctl stop zuul-scheduler zuul-merger zuul-web zuul-executor zuul-fingergw \
   nodepool-launcher nodepool-builder

  # A Zuul SQL database migration need to be performed by Zuul at startup and we have noticed
  # an issue with our DBs content that prevent the migration to success. To fix it, run:
  podman exec -it mysql bash -c 'mysql -uroot -p$MYSQL_ROOT_PASSWORD zuul -e "delete from zuul_buildset where (CHAR_LENGTH(oldrev) > 40 OR CHAR_LENGTH(newrev) > 40 OR CHAR_LENGTH(patchset) > 40);"'

  # Delete the Zuul Ephemeral state from Zookeeper
  zuul_wrapper delete-state

  # Then run the sf-config upgrade command
  sf-config --upgrade

  # Re-create the zuul-scheduler container based on the updated container image
  podman rm zuul-scheduler; /usr/local/bin/container-zuul-scheduler.sh; rm /var/lib/software-factory/versions/zuul-scheduler-updated

  # Now start the zuul-scheduler and ensure that the database migration has been performed without issue.
  systemctl start zuul-scheduler
  tail -f /var/log/zuul/scheduler.log

  # Perform a full restart of Zuul
  ansible-playbook /var/lib/software-factory/ansible/zuul_restart.yml

  # Then restart all Nodepool services
  ansible-playbook /var/lib/software-factory/ansible/nodepool_restart.yml

For more information about the Zuul SQL migration please refer to
the `Zuul changelog <https://zuul-ci.org/docs/zuul/latest/releasenotes.html#relnotes-9-3-0-upgrade-notes>`.
