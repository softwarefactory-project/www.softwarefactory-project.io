.. _zuul-user:

.. warning::

   Zuul (v2) is deprecated and will be removed in Software Factory 3.0


Zuul pipelines and gating configuration
=======================================

`Zuul <https://docs.openstack.org/infra/zuul/>`_ is a software used to gate the
source code repository of a project so that changes are only merged if they pass tests.

Most of its configuration is available to Software Factory users through
the **zuul** directory in the **config** repository.

If you want a deeper understanding of Zuul then check the
`official documentation <http://docs.openstack.org/infra/zuul/>`_ and/or this
`blog post <https://blogs.rdoproject.org/7542/dive-into-zuul-gated-commit-system-2>`_.



Pipelines default configuration
-------------------------------

The default Zuul _layout.yaml provides five pipelines:

* The **check** pipeline: Is used to build a set of jobs
  related to a Gerrit change (a submitted patch) and to report
  a score (-1, or +1) in the **Verified** label according to the global tests results
  within that buildset. This pipeline is managed by the *independent*
  manager of Zuul.

* The **gate** pipeline: Jobs can be configured to run in this pipeline
  after a change has received all the required approvals.
  This pipeline is managed by the *dependent* manager of Zuul and therefore acts
  as a `Gated Commit system <https://en.wikipedia.org/wiki/Gated_Commit>`_.

* The **post** pipeline: Is used to build jobs
  after a change has been merged into the master branch of a
  repository. No score is given to the related change regardless of success
  or failure. This pipeline is managed by the *independent* manager of Zuul.

* The **periodic** pipeline: Is used to run periodic (a bit like a
  cron job) jobs. Since these jobs are not related to a change, no
  score is given either.
  This pipeline is managed by the *independent* manager of Zuul.

* The **tag** pipeline: Jobs are triggered after a tag is pushed on a
  repository. Like the post and periodic pipelines, there is no score associated
  to the results of these jobs.


Adding new pipelines
--------------------

To add a custom pipeline, create a new file, for example zuul/periodic.yaml:

.. code-block:: yaml

    pipelines:
      - name: monthly_periodic
        description: This pipeline run jobs every month
        manager: IndependentPipelineManager
        precedence: low
        trigger:
          timer:
            - time: '0 0 1 * \*'
        failure:
          smtp:
            from: jenkins@fqdn
            to: dev-robot@fqdn
            subject: 'fqdn: Monthly periodic failed'


More informations about Zuul pipelines can be found
`here <http://docs.openstack.org/infra/zuul/zuul.html#pipelines>`_.


.. _zuul-gate:

Project's gate
--------------

To add gating to a repository, create a new file, for example zuul/project.yaml:

.. code-block:: yaml

  projects:
    - name: project-name
      check:
        - check-job1-name
        - check-job2-name
      gate:
        - gate-job1-name
        - gate-job2-name
      periodic:
        - periodic-job-name

.. note::

  * The jobs must be defined in the **job** directory as well, see :ref:`Job configuration<jenkins-user>`.
  * Check and gate jobs can be identical (and often are).


.. _non-voting-jobs:

Configure a job as "Non Voting"
-------------------------------

A test result for a patch determines if the patch is ready to be merged. Zuul
reports an evaluation on Gerrit at the end once the buildset has completed and if this result
is positive, then it allows the patch to be merged on the master branch of a project. But
it can be long and difficult to develop a new test that works as intended (stable,
no false positives, ...) so a good practice is to first set the job as "Non Voting".

For example, let's assume a repository already runs one test job that is known as stable; this
job is used to determine whether a patch can be merged or not. Then you
want to add another experimental job, but you don't want this new job to prevent the merge of
a patch. In that case you can configure Zuul (zuul/projects.yaml) as follows:

.. code-block:: yaml

 jobs:
   - name: demo-job
     branch: master
     voting: false

Zuul will then report the results of "demo-job" as a comment for the tested patch,
but failures won't impact the "Verified" score.
