.. _log-classify:

Log Classify
============

To simplify CI jobs failure, Software Factory integrates logs processing
utilities to analyze and reports root cause.

The log-classify process is based on the logreduce_ utility. The base
principle is to query the build database for nominal builds' outputs
and search for novelties in failed build to extract failure root causes.
More information in this
`talk <https://dirkmueller.github.io/presentation-berlin-log-classify/>`_.

Check the :ref:`operator documentation <log-classify-operator>` to enable
the process and the :ref:`user documentation <log-classify-user>` to
configure it for your job.

.. _logreduce: https://pypi.org/project/logreduce/
