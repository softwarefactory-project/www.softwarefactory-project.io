.. _zuul-user:

Zuul user documentation
=======================

.. note::

  This is a lightweight documentation intended to get users started with setting
  up CI pipelines and jobs. For more insight on what Zuul can do, please refer
  to its `upstream documentation`_ and `migration documentation`_.

.. _`upstream documentation`: https://docs.openstack.org/infra/zuul/user/
.. _`migration documentation`: https://docs.openstack.org/infra/manual/zuulv3.html

Zuul is a *commit gating system* for continuous integration that ensures that
repositories are always in a healthy state. It is up to repositories managers
to define what constitutes a healthy state: for example passing all unit tests,
success in building software, etc.

Software Factory ships with Zuul, which is a major rewrite of Zuul with many improvements.
Most basic concepts remain valid though, so it is advised to read Software Factory's
:ref:`general documentation on Zuul <zuul-user>` before proceeding further.

Some of the major changes reflected in Software Factory are:

* In Zuul's terminology, a **project** is a gated repository
* Projects must be added to the main configuration in the config repository's **zuul** directory
* Jobs can inherit from the **zuul-jobs** repository base jobs
* Pipelines are managed within repositories
* Custom jobs can be defined within repositories
* Github was added as a possible repository source for gating projects, enabling
  Software Factory to act as a third party CI for repositories hosted on Github.

.. _zuul-main-yaml:

Adding a project to the zuul service
------------------------------------

A project file must be submitted to the **config** repository, under the **zuul**
directory. For example, config/zuul/project-name.yaml can contain the following:

.. code-block:: yaml

  - tenant:
      name: local
      source:
        source-name:
          untrusted-projects:
            - project-name


* Leave the tenant name to *local*.
* Replace source-name by the location of the repository: for example, **gerrit** for
  Software Factory's internal gerrit. Other source names, if available, will depend
  on Software Factory's configuration.
* Replace project-name by the repository's name.

.. tip::

  **Why is my project "untrusted" ?**

  For each source, Zuul defines two categories of projects:

  * Projects listed under `config-projects`_
    hold configuration parameters for Zuul, for example pipelines or base jobs
    definitions, or secrets used by these jobs.
  * Projects listed under `untrusted-projects`_
    are the actual repositories for the software being tested or deployed. Zuul
    runs jobs for these projects in a restricted environment.

  Everything the "config-projects" do is already taken care of by Software Factory
  in its **config** and **zuul-jobs** repositories, meaning you should not have
  to add any repository under this category. Therefore repositories should always
  be declared under the "untrusted-projects" category.

.. _`config-projects`: https://docs.openstack.org/infra/zuul/admin/tenants.html#attr-tenant.config-projects

.. _`untrusted-projects`: https://docs.openstack.org/infra/zuul/admin/tenants.html#attr-tenant.untrusted-projects

After merging this change, the config-update job will reload the zuul scheduler.

Adding a predefined job to a project
------------------------------------

A project's CI configuration is happening in repositories, a project can define jobs
and pipelines contents by having a file named *.zuul.yaml* at the root of the project's repository:

.. code-block:: yaml

  ---
  - project:
      name: project-name
      check:
        jobs:
          - linters
      gate:
        jobs:
          - linters

* **name** is the name of the project, same as the one defined in
  Zuul's configuration file earlier
* **check**, **gate** are pipelines defined in Software Factory.

A default deployment of Software Factory comes with the following base jobs:

============= =============================================================
 Name          Description
============= =============================================================
**linters**    Run the bashate, flake8 and yaml linters on relevant files
**tox**        Run tox
**tox-py27**   Run tox -epy27
============= =============================================================

Software Factory can be configured to import the **openstack-infra/zuul-jobs**
jobs library; ask your instance operator if this is the case. A list of the jobs in this
library can be found here_.

.. _here: https://docs.openstack.org/infra/zuul-jobs/jobs.html

A full list of all the jobs that have been built at least once on Software Factory
can be accessed at https://<fqdn>/zuul/local/jobs.html.

Defining a custom job within a project
--------------------------------------

It is possible to define jobs specific to a project within its repository. This
is done in the *.zuul.yaml* file at the root of the repository. Jobs are based
on Ansible playbooks.

For example, the following .zuul.yaml file will define a job called **unit-tests**
to be run in the **check** pipeline along the linters:

.. code-block:: yaml

  ---
  - job:
      name: unit-tests
      parent: base
      description: this is running the unit tests for this project
      run: playbooks/unittests.yaml
      nodeset:
        nodes:
          - name: test-node
            label: dib-centos-7

  - project:
      name: project-name
      check:
        jobs:
          - unit-tests
          - linters

* setting **parent: base** allows this job to inherit from the default *pre* and
  *post* playbooks which are run before and after the custom job's playbook.
  These playbooks prepare the work environment and automatically publish artifacts
  and logs on Software Factory's log server, so while not mandatory, it is advised
  to add this setting to make use of Software Factory's integrations.
* **nodeset** defines the nodes that will be spawned to build the job. *Label*
  refers to nodepool label definitions, see the :ref:`nodepool documentation <nodepool-user>`
  for further details. *Name* is the name of the node as it will appear in
  the job's playbook inventory.

The previous example expects the Ansible playbook "playbooks/unittests.yaml" (or
"playbooks/unittests/run.yaml") to be present in the project's repository. Here
is an example of what this playbook could contain:

.. code-block:: yaml

  ---
  - hosts: test-node
    tasks:
      - name: install tox package
        yum:
          name: python-tox
          state: present
        become: yes
      - name: run unit tests
        command: tox
        args:
          chdir: {{ zuul.project.src_dir }}/tests

Further documentation can be found online:

* Ansible playbooks_, modules_ documentation
* `Predefined variables available in jobs`_

.. _playbooks: http://docs.ansible.com/ansible/latest/playbooks.html

.. _modules: http://docs.ansible.com/ansible/latest/modules_by_category.html

.. _`Predefined variables available in jobs`: https://docs.openstack.org/infra/zuul/user/jobs.html#variables


.. _zuul-artifacts-export:

Export logs artifacts to the logserver
--------------------------------------

After a job ran, Software Factory exports the job's *console* log to
the internal log server.

When a job generate extra artifacts, such as log files, a *post-run* playbook
can be written to export the artifacts to *zuul.executor.log_root*. Then
Software Factory base job's *post-run* will push these artifacts to the internal log server.

An example of a *fetch-logs.yaml* playbook.

.. code-block:: yaml

 ---
 - hosts: all
   tasks:
     - name: Upload logs
       synchronize:
         src: '{{ zuul.project.src_dir }}/logs'
         dest: '{{ zuul.executor.log_root }}'
         mode: pull
         copy_links: true
         verify_host: true
         rsync_opts:
           - --include=/logs/**
           - --include=*/
           - --exclude=*
           - --prune-empty-dirs

A job can use that playbook as *post-run* then each files
in the *zuul.project.src_dir/logs/* will be exported to the log server.

.. code-block:: yaml

  ---
  - job:
      name: build
      parent: base
      description: My job
      run: playbooks/run.yaml
      post-run: playbooks/fetch-logs.yaml


.. _zuul-artifacts-export-logstash:

Export logs artifacts to logstash
---------------------------------

A job can be configured to export specific artifacts
to logstash to make them available to the search via Kibana.
The ELK stack must be activated on the Software Factory instance.

The job variable *logstash_processor_config* need to be provided
as follow:

.. code-block:: yaml

  ---
  - job:
      name: build
      parent: base
      description: My job
      run: playbooks/run.yaml
      post-run:
        - playbooks/fetch-logs.yaml
      vars:
        logstash_processor_config:
          files:
            - name: logs/.*\.log
            - name: job-output\.txt
              tags:
                - console
                - console.html

With this definition, zuul will export all the generated artifacts
located in the *logs/* directory to logstash. The *logstash_processor_config*
variable definition overwrites the one from the Software Factory base job,
that's why, the *job-output.log* (console) must specified too.

Create a secret to be used in jobs
----------------------------------

Zuul provides a public key for every project. This key needs to be used to encrypt
secret data. To fetch a project's public key:

.. code-block:: bash

  curl -O https://<fqdn>/zuul/api/tenant/<tenant>/key/<project>.pub

The *tools/encrypt_secret.py* tool, from the Zuul repository,
can be used to create the YAML tree to be pushed in the project *.zuul.d/* directory.

.. code-block:: bash

  ./encrypt_secret.py --infile secret.data --outfile secret.yaml https://<fqdn>/zuul/api/tenant/<tenant> <project>

Then *<name>* and *<fieldname>* fields that are placeholders must be replaced in the
generated *secret.yaml* file.

A secret used in a job must be defined in the same project than the job is defined.
The user should read carefully the section_ about secrets.

.. _section: https://docs.openstack.org/infra/zuul/user/config.html?highlight=secret#secret


Web Interface
-------------

Zuul comes with the following web interface:

Status
......

Zuul's status can be reached at https://<fqdn>/zuul/local/status.html

This page shows the current buildsets in Zuul's pipelines. Filtering options are
available.

Each buildset can be expanded to show the advancement of its builds. Clicking on a build will
open a stream of its logs in real time.

Jobs
....

Zuul's Jobs dashboard can be reached at https://<fqdn>/zuul/local/jobs.html

This page lists all the jobs that have been built at least once by Zuul. Filtering
options are available.

Builds
......

Zuul's Builds dashboard can be reached at https://<fqdn>/zuul/local/builds.html

This page lists all the builds and build sets that have completed. Filtering
options are available.


.. _zuul-github-app-user:

Configure a GitHub App
----------------------

After a GitHub Application is created and configured in Software Factory (see this :ref:`guide <zuul-github-app-operator>`),
to add the application to your projects, follow this `documentation <https://help.github.com/articles/installing-an-app-in-your-organization/#installing-a-github-app-in-your-organization>`_:

* Visit the application page, e.g.: https://github.com/apps/my-org-zuul
* Click "Install"
* Select your GitHub organisation
* Select the repositories to install the application on
* Click "Install"

Then you'll be redirected to the Setup URL with the instruction to finish the configuration, checkout the :ref:`Zuul user documentation <zuul-main-yaml>`:

* Update the config repository to add the projects to the zuul main.yaml file.
* Create a Pull Request to add a .zuul.yaml to your project and verify it works.

.. note::

  Software Factory pre-configures its default *check* pipeline to trigger jobs according to the pull request
  status. Status of jobs running in the *check* pipeline will be reported in the pull request. You might want
  to define specific pipelines like a *github-gate* and a *github-post*. To do so you should propose them in
  the *config* repository *zuul.d/*. Refer to the upstream manual_.

.. _manual: https://docs.openstack.org/infra/zuul/admin/drivers/github.html

