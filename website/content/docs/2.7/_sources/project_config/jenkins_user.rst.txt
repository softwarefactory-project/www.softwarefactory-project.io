.. _jenkins-user:

.. warning::

   Jenkins is deprecated and will be removed in Software Factory 3.0

Jenkins jobs configuration
==========================

`Jenkins <https://jenkins.io/>`_ is a continuous integration tool.

Jobs are configured in the config repository's **jobs** directory using
`Jenkins Job Builder (JJB) <http://docs.openstack.org/infra/jenkins-job-builder/>`_.
JJB is a definition format in yaml that allows you to easily configure and define Jenkins jobs.


Default jobs
------------

There are 3 template jobs defined by default for each repository:

* **{name}-unit-tests**:           run unit tests
* **{name}-functional-tests**:     run functional tests
* **{name}-publish-docs**:         publish documentation after a change is merged

These jobs expect the following scripts to be present at the root level of a
repository, respectively:

* run_tests.sh
* run_functional-tests.sh
* publish_docs.sh


If a repository hosts a python module, the template job **{name}-upload-to-pypi** can
be used to push a package to a PyPI server. A valid .pypirc file set as a
Jenkins credential must exist first; the id of the credential must then be
passed as the variable 'pypirc' when configuring the job for the repository.
More information about the .pypirc file format can be found
`here <https://docs.python.org/2/distutils/packageindex.html#pypirc>`_.


Using default jobs
-------------------

To have a default job run on your repository's CI pipeline, create a new file,
for example jobs/project.yaml:

.. code-block:: yaml

 - project:
     name: sfstack
     jobs:
       - 'sfstack-unit-tests'
       - 'sfstack-functional-tests'


The above example adds two jobs, 'sfstack-unit-tests' and 'sfstack-functional-tests',
to sfstack's CI pipeline.
See :ref:`zuul project gating<zuul-gate>` to see how to automatically run
those jobs on new patches.


Adding custom jobs
------------------

New jobs can be created without using the provided template:

.. code-block:: yaml

 - job:
     name: 'demo-job'
     defaults: global
     builders:
       - prepare-workspace
       - shell: |
           cd $ZUUL_PROJECT
           set -e
           sloccount .
           echo do a custom check/test
     wrappers:
       - credentials-binding:
         - file:
            credential-id: c6a71f95-be85-4cad-9cec-3bea066ee80a
            variable: my_secret_file
     triggers:
       - zuul
     node: centos7-slave

Some explanations about this example:

* **defaults**: is the way the build's workspace is prepared. In Software Factory's default configuration
  this defines a freestyle project that can be run concurrently.
* **builders**: builders are the job's code. It is important to note that it uses the default
  **"prepare-workspace"** builder and then **"shell"**. The former uses **"zuul-cloner"** to
  clone the repository at the change to be tested in the workspace. Then the latter
  defines shell commands to execute within the build's workspace.
* **wrappers** for credential bindings (optional): this makes credentials defined in Jenkins available
  in the build's workspace. In this example, a file will be created and stored in the path set by the
  shell variable ${my_secret_file} for the duration of the job.
* **triggers**: using the "zuul" trigger is mandatory to expose environment variables (set by
  zuul's scheduler) in the build's workspace, as default builders need these. ZUUL_PROJECT is
  an example of these variables.
* **node**: is the slave label that specifies where the job can be built.

CLI
---
.. warning::

  The CLI only supports jenkins as a job builder. Support for zuul-job is coming!

The *sfmanager* utility lets users interact with jobs. The following operations are available:

* list informations about builds. Builds can be filtered by name and by patchset.
* show the parameters used by a given build
* show the logs of a completed build
* cancel a running build
* execute a new build of a job; parameters from a previous build can be fetched automatically.

Please refer to sfmanager's contextual help for more details.
