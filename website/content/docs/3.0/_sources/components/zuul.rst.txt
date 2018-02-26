.. _zuul_components:

Continuous Integration, Delivery, and Deployment system
-------------------------------------------------------

`Zuul <https://docs.openstack.org/infra/zuul>`_ is the
service in charge of running tests and managing projects's pipeline such as gate and
post deployment:

* Jobs are written in ansible and stored in repository
* Secrets management system to manage deployment/publishing key
* Simple multi-node jobs description

The service is pre-configured with five pipelines:

* A **check** pipeline, used for preliminary tests on upcoming changes
* A **gate** pipeline, used to make sure an approved change can be merged
* A **post** pipeline, executing jobs right after a change has been merged
* A **release** pipeline, executing jobs after a tag has been pushed on a repository
* A **periodic** pipeline, building jobs at a regular interval, usually daily

When deployed locally, the service is configured with a few roles:

* prepare-workspace: copy project with under review change
* emit-ara-report: generate html logs of ansible play
* validate-host: verify and log information about build host
* upload-logs: upload job logs to a static webserver

.. image:: imgs/zuul.png
   :scale: 50 %
