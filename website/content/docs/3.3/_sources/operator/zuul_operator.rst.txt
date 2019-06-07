.. note::

  This is a lightweight documentation intended to get operators started with setting
  up the Zuul service. For more insight on what Zuul can do, please refer
  to upstream documentation_.

.. _documentation: https://docs.openstack.org/infra/zuul/

Operate zuul
============

The Zuul service is installed with rh-python35 software collections:

* The configuration is located in /etc/zuul
* The logs are written to /var/log/zuul
* The services are prefixed with rh-python35-

A convenient wrapper for the command line is installed in /usr/bin/zuul.

By default, no merger are being deployed because the executor service
can perform merge task. However, a merger can also be deployed to speed
up start time when there are many projects defined.

Jobs default nodeset
--------------------

The default configuration in */etc/software-factory/sfconfig.yaml* for zuul
nodeset is to use the label *runc-centos*. This label is only available if you
added the role *hypervisor-runc* in */etc/software-factory/arch.yaml*. If you
don't use this role, you should specify the nodeset to use for jobs. For
example, if you have defined a dib image in nodepool configuration, you should
update */etc/software-factory/sfconfig.yaml* to specify the default nodeset name
and label, for instance:

.. code-block:: yaml

    zuul:
      default_nodeset_name: dib-centos-7
      default_nodeset_label: dib-centos-7

Then, run :ref:`sfconfig  <configure_reconfigure>` to apply the modification

Save and restore the queues
---------------------------

The zuul scheduler service is stateless and stopping the process will lose track
of running jobs. However the zuul-changes.py utility can be used
to save and restore the current state:

.. code-block:: bash

    # Print and save all builds in progress to /var/lib/zuul/zuul-queues-dump.sh
    /usr/libexec/software-factory/zuul-changes.py dump

    systemctl restart rh-python35-zuul-scheduler

    # Reload the previous state
    /usr/libexec/software-factory/zuul-changes.py load

The periodic and post pipelines are not dumped by this tool.

.. _restart-zuul-services:

Restart Zuul services
---------------------

The *zuul_restart.yml* playbook stops and restarts Zuul services and
automatically restore the scheduler's jobs queues.

.. code-block:: yaml

  ansible-playbook /var/lib/software-factory/ansible/zuul_restart.yml


Configure an external gerrit (use Software Factory as a Third-Party CI)
-----------------------------------------------------------------------

Refer to the :ref:`Third-Party-CI Quick Start guide <tpci-quickstart>`

.. _zuul-github-app-operator:

Add a git connection
--------------------

In /etc/software-factory/sfconfig.yaml add in *git_connections*:

.. code-block:: yaml

  - name: gerrithub
    baseurl: https://review.gerrithub.io

Then run **sfconfig** to apply the configuration.

Create a GitHub app
-------------------

To create a GitHub app on my-org follow this
`github documentation <https://developer.github.com/apps/building-integrations/setting-up-and-registering-github-apps/registering-github-apps/>`_:

* Open the App creation form:

  * to create the app under an organization, go to `https://github.com/organizations/<organization>/settings/apps/new`
  * to create the app under a user account, go to `https://github.com/settings/apps/new`

* Set GitHub App name to "my-org-zuul"
* Set Homepage URL to "https://fqdn"
* Set Setup URL to "https://fqdn/docs/user/zuul_user.html"
* Set Webhook URL to "https://fqdn/zuul/api/connection/github.com/payload"
* Create a Webhook secret
* Set permissions:

  * Repository Administraion: Read (get branch protection status)
  * Repository contents: Read & Write (write to let zuul merge change)
  * Issues: Read & Write
  * Pull requests: Read & Write
  * Commit statuses: Read & Write

* Set events subscription:

  * Commit comment
  * Create
  * Push
  * Release
  * Issue comment
  * Issues
  * Label
  * Pull request
  * Pull request review
  * Pull request review comment
  * Status

* Set Where can this GitHub App be installed to "Any account"
* Create the App
* In the 'General' tab generate a Private key for your application, and download the key to a secure location

To configure the Github connection in sfconfig.yaml, add to the **github_connections** section:

.. code-block:: yaml

  - name: "github.com"
    webhook_token: XXXX # The Webhook secret defined earlier
    app_id: 42 # The ID shown in the about section of the app.
    app_key: /etc/software-factory/github.key # Path to the private key generated during the setup of the app.
    app_name: app-name
    label_name: mergeit # Label of the tag that must be set to let Zuul trigger the gate pipeline.

Then run **sfconfig** to apply the configuration. And finally verify in the 'Advanced'
tab that the Ping payload works (green tick and 200 response). Click "Redeliver" if needed.

.. note::

   It's recommended to use a GitHub app instead of manual webhook. When using
   manual webhook, set the api_token instead of the app_id and app_key.
   Manual webhook documentation is still TBD...


Check out the :ref:`Zuul GitHub App user documentation<zuul-github-app-user>` to start using the application.

More information about the Zuul's Github driver can be found in the Zuul Github driver manual_.

.. _manual: https://docs.openstack.org/infra/zuul/admin/drivers/github.html


Use openstack-infra/zuul-jobs
-----------------------------

The zuul-scheduler can automatically import all the jobs defined in
the zuul-ci.org/zuul-jobs repository. Set the zuul.upstream_zuul_jobs options
to True in sfconfig.yaml


.. _restart_config_update:

Restarting a config-update job
----------------------------------

When the *config-update* job fails, you can manually restart the job using
the command bellow. Make sure to set the *ref-sha* which is the last commit
hash of the config repository.

.. code-block:: bash

    zuul enqueue-ref --trigger gerrit --tenant local --pipeline post --project config --ref master --newrev ref-sha

The job will be running in the post pipeline of the Zuul status page.


Troubleshooting non starting jobs
---------------------------------

* First check that the project is defined in /etc/opt/rh/rh-python35/zuul/main.yaml
* Then check in scheduler.log that it correctly requested a node and submitted a
  job to the executor
* When zuul reports *PRE_FAILURE* or *POST_FAILURE*,
  then the executor's debugging needs to be turned on
* Finally passing all loggers' level to DEBUG in
  /etc/opt/rh/rh-python35/zuul/scheduler-logging.yaml then restarting the service
  rh-python35-zuul-scheduler might help to debug.


Troubleshooting the executor
----------------------------

First you need to enable the executor's *keepjob* option so that ansible logs are available on dist:

.. code-block:: bash

    /opt/rh/rh-python35/root/bin/zuul-executor keep
    /opt/rh/rh-python35/root/bin/zuul-executor verbose

Then next job execution will be available in /tmp/systemd-private-*-rh-python35-zuul-executor.service-*/tmp/

In particular, the work/ansible/job-logs.txt usually tells why a job failed.

When done with debugging, deactivate the keepjob option by running:

.. code-block:: bash

    /opt/rh/rh-python35/root/bin/zuul-executor nokeep
    /opt/rh/rh-python35/root/bin/zuul-executor unverbose
