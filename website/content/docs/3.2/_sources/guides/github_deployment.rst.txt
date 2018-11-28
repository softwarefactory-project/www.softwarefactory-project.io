.. _github_deployment:

Deploy Software Factory for a Github Organizations
--------------------------------------------------

In this guide, we will deploy SF as a CI/CD service for github projects.

Deploy a minimal architecture
.............................

On a CentOS-7 system, deploy the minimal architecture:

.. code-block:: bash

  yum install -y https://softwarefactory-project.io/repos/sf-release-3.2.rpm
  yum update -y
  yum install -y sf-config
  cp /usr/share/sf-config/refarch/zuul-minimal.yaml /etc/software-factory/arch.yaml
  sfconfig


Create a Github Application
...........................

Follow this :ref:`zuul-github-app-operator` documentation to create a Github
application. To continue you will need `webhook_token`, an `app_id` and the
`app_key` (the private key file). Copy the `app_key` to /etc/software-factory.

Install the application for all the projects of the organization.

.. _create_config_job_repos:

Create a config and jobs repository
...................................

In your Github organization or account, create a couple of repositories for the
config and the jobs, for example named `sf-config` and `sf-jobs`.

.. note::

   The config and jobs projects need to be public

The sfconfig script can automatically push the content and keep it up to date
for you. In that case you need to register the admin_rsa key in your Github
account: https://github.com/settings/keys Import the file /root/.ssh/id_rsa.pub
from the server.

.. note::

   Make sure the GitHub application is installed on the config and jobs projects
   so that standard jobs and config-update are scheduled.

.. _update_the_configuration:

Update the configuration
........................

Edit /etc/software-factory/sfconfig.yaml:

.. code-block:: yaml

   config-locations:
     config-repo: https://github.com/MyOrg/sf-config
     jobs-repo: https://github.com/MyOrg/sf-job

   zuul:
     github_connections:
       - name: github.com
         webhook_token: XXX
         app_id: YYY
         app_name: app-name
         label_name: merge
         app_key: /etc/software-factory/github.key

Then run `sfconfig` again to apply the update.


Enable branch protection (optional)
...................................

Once you are satisfied with the CI configuration, branch protection should
be enabled using this :ref:`zuul-github-branch-protection` documentation.


Add projects
............

In the *config* repo, new projects can be added, for example
create a zuul/projects.yaml file with:

.. code-block:: yaml

   - tenant:
       name: local
       source:
         github.com:
           untrusted-projects:
             - MyOrg/demo-project
             - MyOrg/demo-project-client


Alternatively, since Software Factory 3.1, Github projects can be defined via the resources
engine. See this :ref:`section <zuul-github-resources>`.

Conclusion
..........

* The Zuul service is running at https://hostname/zuul
* Logserver is configured at https://hostname/logs
* The sf-config project has been provisioned with a base job using
  the logserver.
* The sf-jobs project has been provisioned with demo jobs and roles ready
  to be used. See https://hostname/zuul/t/local/jobs.html for the list of
  available jobs.

Next things to do (guides are pending):

* Configure gate pipeline for your projects
* Enable logstash
