.. _log-classify-operator:

Log Classify Operator
=====================

Software Factory bundles :ref:`log classification<log-classify>` utilities to
enable automatic anomaly detection in CI job logs.

The only supported integration is with the zuul base job,
where anomaly detection automatically happens at the end of the job.


Base Job Integration
--------------------

To enable the zuul-jobs roles in the base job, just add "log-classify" to the
install server role list and run sfconfig:

.. code-block:: yaml

   # /etc/software-factory/arch.yaml
   ---
   inventory:
     - name: managesf
       roles:
         - install-server
         - log-classify

This automatically installs the utility on the executor nodes and configures
the base job roles to generate a report when a job fail.

The integration also adds an upload model action to store any models built
by the job. The default location is /var/www/logs/classifiers on the logserver.
Further failure may re-use pre-built models. The models are automatically
re-created every seven days.

Check the :ref:`user documentation <log-classify-user>` for further
configuration.
