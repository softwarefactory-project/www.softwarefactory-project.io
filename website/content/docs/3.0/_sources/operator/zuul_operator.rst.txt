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


Configure an external gerrit (use Software Factory as a Third-Party CI)
-----------------------------------------------------------------------

Refer to the :ref:`Third-Party-CI Quick Start guide <tpci-quickstart>`

.. _zuul-github-app-operator:

Create a GitHub app
-------------------

To create a GitHub app on my-org follow this
`github documentation <https://developer.github.com/apps/building-integrations/setting-up-and-registering-github-apps/registering-github-apps/>`_:

* Open the App creation form:

  * to create the app under an organization, go to `https://github.com/organizations/<organization>org/settings/apps/new`
  * to create the app under a user account, go to `https://github.com/settings/apps/new`

* Set GitHub App name to "my-org-zuul"
* Set Homepage URL to "https://fqdn"
* Set Setup URL to "https://fqdn/docs/project_config/zuul_user.html#adding-a-project-to-the-zuul-service"
* Set Webhook URL to "https://fqdn/zuul/connection/github.com/payload"
* Create a Webhook secret
* Set permissions:

  * Commit statuses: Read & Write
  * Issues: Read & Write
  * Pull requests: Read & Write
  * Repository contents: Read & Write (write to let zuul merge change)

* Set events subscription:

  * Label
  * Status
  * Issue comment
  * Issues
  * Pull request
  * Pull request review
  * Pull request review comment
  * Commit comment
  * Create
  * Push
  * Release

* Set Where can this GitHub App be installed to "Any account"
* Create the App
* In the 'General' tab generate a Private key for your application, and download the key to a secure location

To configure the Github connection in sfconfig.yaml, add to the **github_connections** section:

.. code-block:: yaml

  - name: "github.com"
    webhook_token: XXXX # The Webhook secret defined earlier
    app_id: 42 # Can be found under the Public Link on the right hand side labeled ID.
    app_key: | # In Github this is known as Private key and must be collected when generated
      -----BEGIN RSA PRIVATE KEY-----
      KEY CONTENT HERE
      -----END RSA PRIVATE KEY-----

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
the openstack-infra/zuul-jobs repository. Use this command line to enable
its usage:

.. code-block:: bash

    sfconfig --zuul-upstream-jobs


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

    /opt/rh/rh-python35/root/bin/zuul-executor -c /etc/zuul/zuul.conf keep

Then next job execution will be available in /tmp/systemd-private-*-rh-python35-zuul-executor.service-*/tmp/

In particular, the work/ansible/job-logs.txt usually tells why a job failed.

When done with debugging, deactivate the keepjob option by running:

.. code-block:: bash

    /opt/rh/rh-python35/root/bin/zuul-executor -c /etc/opt/rh/rh-python35/zuul/zuul.conf nokeep
