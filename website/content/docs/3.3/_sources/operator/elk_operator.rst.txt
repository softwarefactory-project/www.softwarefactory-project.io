.. _elk-operator:

ELK service
===========

Software Factory bundles an ELK stack to ease search through
job's logs artifacts. Once activated, job's console of every
build are exported through logstash and then available to
the search via Kibana.

A Software Factory user might want to export more artifacts
than the job's console. Indeed a job may generate additional
log files. In that case a custom zuul *post-run* job must be defined.
In order to do so a user must refer to :ref:`Export logs artifacts to logstash <zuul-artifacts-export-logstash>`

How to activate
---------------

These services are not deployed by default but can be activated by adding
the following components in */etc/software-factory/arch.yaml*:

.. code-block:: yaml

 - elasticsearch
 - logstash
 - job-logs-gearman-client
 - job-logs-gearman-worker
 - kibana

Then running:

.. code-block:: bash

 # sfconfig

The Kibana interface should be accessible via the Software Factory top menu under
the name Kibana.
