.. _restart_config_update:

How to restart a config-update job
----------------------------------

When the *config-update* job fails, you can manually restart the job using
the command bellow. Make sure to set the *ref-sha* which is the last commit
hash of the config repository.

.. code-block:: bash

    zuul enqueue-ref --trigger gerrit --tenant local --pipeline post --project config --ref master --newrev ref-sha

The job will be running in the post pipeline of the Zuul status page.
