.. _log-classify-user:

Log Classify User
=================

When :ref:`log classify <log-classify>` is enabled
(see :ref:`operator doc<log-classify-operator>`), then a report.html is
created in failed job logs artifacts.

When a job fails, a post-action will compare the job output with previous
successful build to detect anomaly. When nominal builds are found, the action
creates a log-classify.html report in the jobs artifacts.

To disable the post action, set the job variable logclassify_optin to false,
e.g.:

.. code-block:: yaml

   - project:
       jobs:
         check:
           - linters:
               vars:
                 logclassify_optin: false

To make the report directly available from the failed job links, set the
logclassify_report to true, for example in the job definition:

.. code-block:: yaml

   - job:
       name: my-job
       vars:
         logclassify_report: true
