.. _log-classify:

.. note::

   This is a tech-preview introduced in the version 3.1 of Software Factory.


Log-Classify detect anomaly in jobs
===================================

When a job fails, a post-action will compare the job output with previous
successful build to detect anomaly. The action creates a log-classify.html
report in the jobs artifacts.

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
logclassify_report to true.

When a model is built, it is automatically published to the logserver in
the "classifiers" directory. Other Zuul executor may then re-use a model
if it is already built.
