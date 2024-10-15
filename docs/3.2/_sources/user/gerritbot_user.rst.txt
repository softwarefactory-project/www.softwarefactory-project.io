.. _gerritbot-user:

Gerritbot notification channels configuration
=============================================

Once the service is running (see :ref:`operator configuration <gerritbot-operator>`),
you can configure the irc channels to send notifications to:

* clone the config repository with git
* add a new file or edit one in the **config/gerritbot** directory:

.. code-block:: yaml

  irc-channel-name:
    events:
      - change-created
      - change-merged
    projects:
      - myproject
    branches:
      - master

* submit and merge the config change.
* the gerritbot configuration will be updated with the automated post-merge run of **config-update**.
