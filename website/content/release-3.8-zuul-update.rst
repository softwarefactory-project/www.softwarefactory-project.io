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

.. code-block:: bash
  # Backup your Software Factory data
  ansible-playbook /var/lib/software-factory/ansible/sf_backup.yml

  # Install this specific sf-config package
  yum install https://softwarefactory-project.io/repos/sf-config-3.8.8.16.gc8a3619-4.el7.noarch.rpm

  # Ensure to deactivate the automatic restart of Zuul and Nodepool
  echo "disable_zuul_autorestart: true" >> /etc/software-factory/custom-vars.yaml
  echo "disable_nodepool_autorestart: true" >> /etc/software-factory/custom-vars.yaml

  # A Zuul SQL database migration need to be performed by Zuul at startup and we have noticed
  # an issue with our DBs content that prevent the migration to success.
  #
  # First check for the issue
  grep mysql_root_password /var/lib/software-factory/bootstrap-data/secrets.yaml
  podman exec -it mysql mysql -uroot -p<mysql_root_password>
  MariaDB> use zuul;
  MariaDB [zuul]> select id, oldrev, newrev, patchset from zuul_buildset where (CHAR_LENGTH(oldrev) > 40 OR CHAR_LENGTH(newrev) > 40 OR CHAR_LENGTH(patchset) > 40);
  # Important ! -> Update or remove buildset entries that are returned by that command. The new schema cannot handle oldrev, newrev or patchset values that exceed 40 chars long.

  # Then run the sf-config upgrade command
  sf-config --upgrade

  # Stop all Zuul services (adapt the command if services are running on multiple nodes)
  systemctl stop zuul-scheduler zuul-merger zuul-web zuul-executor

  # Now start the zuul-scheduler and ensure that the database migration has been performed without issue.
  systemctl start zuul-scheduler
  tail -f /var/log/zuul/scheduler.log

  # Then restart all Zuul and Nodepool services (adapt the command if services are running on multiple nodes)
  systemctl start zuul-merger zuul-web zuul-executor
  systemctl restart nodepool-launcher nodepool-builder

For more information about the Zuul SQL migration please refer to
the `Zuul changelog <https://zuul-ci.org/docs/zuul/latest/releasenotes.html#relnotes-9-3-0-upgrade-notes>`.
