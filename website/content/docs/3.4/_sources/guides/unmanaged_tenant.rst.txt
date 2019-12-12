.. _unmanaged_tenant:

Create an unmanaged tenant
--------------------------

In this guide, we will create a standalone tenant from scratch where jobs and
pipelines are not managed by sfconfig.
The tenant will be named *org-test*, its config *org-test-config* and its jobs
*org-test-jobs*.

Follow this guide as an admin user on the install server.


Create a new config project
...........................

The first step is to create a new project, add this file to the resources:

.. code-block:: yaml

   # /root/config/resources/tenant-org-test.yaml
   ---
   resources:
     tenants:
       org-test:
         description: "The org-test tenant."
         url: "https://sftests.com/manage"
         default-connection: gerrit

     projects:
       org-test:
         tenant: org-test
         description: The org-test project
         source-repositories:
           - org-test-config:
               zuul/config-project: True
           - org-test-jobs
           - zuul-jobs:
               connection: gerrit
               # Using 'zuul/' prefix, we set zuul tenant config options.
               zuul/include: [job]
               # Shadow means that job definition in this project are
               # overridden by the org-test-jobs.
               zuul/shadow: org-test-jobs

     repos:
       org-test-config:
         description: The org-test config repository
         acl: org-test-acl
       org-test-jobs:
         description: The org-test jobs repository
         acl: org-test-acl

     acls:
       org-test-acl:
         file: |
           [access "refs/*"]
             read = group org-test-core
             owner = group org-test-ptl
           [access "refs/heads/*"]
             label-Code-Review = -2..+2 group org-test-core
             label-Code-Review = -2..+2 group org-test-ptl
             label-Verified = -2..+2 group org-test-ptl
             label-Workflow = -1..+1 group org-test-core
             label-Workflow = -1..+1 group org-test-ptl
             label-Workflow = -1..+0 group Registered Users
             abandon = group org-test-core
             submit = group org-test-ptl
             read = group org-test-core
             read = group Registered Users
           [access "refs/meta/config"]
             read = group org-test-core
             read = group Registered Users
           [receive]
             requireChangeId = true
           [submit]
             mergeContent = false
             action = fast forward only
         groups:
           - org-test-ptl
           - org-test-core

     groups:
       org-test-ptl:
         description: Team lead for the org-test tenant
         members:
           - admin@sftests.com
       org-test-core:
         description: Team core for the org-test tenant
         members: []

Edit the file:

- Update *sftests.com* with the fqdn of your deployment.
- Change zuul-jobs location if you used the upstream_zuul_jobs option. Check
  the /root/config/resources/_internal.yaml file for the zuul-jobs definition.
- Update the org-test-ptl and org-test-core members lists accordingly.

Then submit the file:

.. code-block:: bash

   cd /root/config
   git add resources/tenant-org-test.yaml
   git commit -m "Add org-test tenant"
   git review
   # If zuul verified +1 the review, you can push
   git push


After config-update succeed, the tenant is ready to be used.


Access the org-test Zuul tenant
...............................

On the local status page, you can switch tenant by clicking the "Tenant local"
button on the top right. This links to https://sftests.com/zuul/tenants .

Alternatively you can go directly to
https://sftests.com/zuul/t/org-test/status .

The next step is to configure the config project to add a pipeline and
a base job.


Tenant config repository initialization
.......................................

To configure the tenant, clone its config project:

.. code-block:: bash

   git clone https://sftests.com/r/org-test-config
   cd org-test-config
   mkdir -p zuul.d playbooks/base

First you need to create a pipeline:

.. code-block:: yaml

   # org-test-config/zuul.d/pipelines.yaml
   ---
   - pipeline:
       name: check
       description: |
         Newly uploaded patchsets enter this pipeline to receive an
         initial +/-1 Verified vote.
       manager: independent
       require:
         gerrit:
           open: True
           current-patchset: True
       trigger:
         gerrit:
           - event: patchset-created
       start:
         gerrit:
           verified: 0
       success:
         gerrit:
           verified: 1
         sqlreporter:
       failure:
         gerrit:
           verified: -1
         sqlreporter:

Then you need to create a default base job:

.. code-block:: yaml

   # org-test-config/zuul.d/jobs.yaml
   ---
   - job:
      name: base
      parent: null
      description: The base job.
      pre-run: playbooks/base/pre.yaml
      post-run: playbooks/base/post.yaml
      roles:
        # Note: change zuul-jobs name when using the upstream_zuul_job option
        # Check /root/config/zuul.d/_jobs-base.yaml for the definition.
        - zuul: zuul-jobs
      timeout: 1800
      attempts: 3
      secrets:
        - site_sftests_logserver
      nodeset:
        nodes:
          # Note: change the default nodeset
          - name: container
            label: pod-centos

Then you need to create a secret for the log server from the install-server
(the zuul_logserver_rsa private key is kept in /var/lib/software-factory):

.. code-block:: bash

   curl -O https://git.zuul-ci.org/cgit/zuul/plain/tools/encrypt_secret.py
   python encrypt_secret.py --tenant org-test \
     --infile /var/lib/software-factory/bootstrap-data/ssh_keys/zuul_logserver_rsa \
     https://sftests.com/zuul/ org-test-config

Copy the output to a zuul.d file:

.. code-block:: yaml

   # org-test-config/zuul.d/secrets.yaml
   ---
   - secret:
      name: site_sftests_logserver
      data:
        fqdn: sftests.com
        path: /var/www/logs
        ssh_known_hosts: sftests.com ssh-rsa AAAAB3... # the stdout of ssh-keyscan sftests.com | grep ssh-rsa
        ssh_username: loguser
        ssh_private_key: !encrypted/pkcs1-oaep
          - k9eg8co3TWiAGB73SBnr6tGkm3jITIFFv8Vjm...
            ...
            ...
          - ...

Note that you could use another private key and logserver location for this
tenant.

Finally create the base job playbook:

.. code-block:: yaml

   # org-test-config/playbooks/base/pre.yaml
   ---
   - hosts: localhost
     tasks:
       - block:
           - import_role: name=emit-job-header
           - import_role: name=log-inventory
         vars:
           zuul_log_url: "https://sftests.com/logs"

   - hosts: all
     roles:
       - prepare-workspace

   # org-test-config/playbooks/base/post.yaml
   ---
   - hosts: localhost
     roles:
       - role: add-fileserver
         fileserver: "{{ site_sftests_logserver }}"

   - hosts: "{{ site_sftests_logserver.fqdn }}"
     gather_facts: false
     tasks:
       - block:
           - import_role: name=upload-logs
         vars:
           zuul_log_url: "https://sftests.com/logs"
           zuul_logserver_root: /var/www/logs


Then submit the initial configuration:

.. code-block:: bash

   git add playbooks/ zuul.d/
   git commit -m "Initial configuration"
   git push git+ssh://sftests.com:29418/org-test-config master


On the status page a new "check" pipeline is now configured, and there shouldn't
be any config-errors indicated by a yellow bell on the top right.


Validate the base job
.....................

In the org-test-jobs project, create a first job:

.. code-block:: bash

   git clone https://sftests.com/r/org-test-jobs
   cd org-test-jobs
   mkdir zuul.d


Add a jobs.yaml file

.. code-block:: yaml

   # org-test-jobs/zuul.d/jobs.yaml
   ---
   - job:
       name: org-codestyle
       parent: run-test-command
       vars:
         test_command: yamllint .


Configure the job for the org-test-jobs project

.. code-block:: yaml

   # org-test-jobs/zuul.d/project.yaml
   ---
   - project:
       check:
         jobs:
           - org-codestyle

Submit the change and verify the job ran successfully:

.. code-block:: bash

   git add zuul.d
   git commit -m "Add org-codestyle job"
   git review

Once the base job and default jobs are working, proceed to the next steps.


Finalize tenant creation
........................

- Add gate, post, release and other pipelines by adapting the definition from
  the local tenant: /root/config/zuul.d/_pipelines.yaml

- Setup check and gate jobs for the org-test-config and org-test-jobs repository.

- Define project-template and define the PTI, see:
  https://zuul-ci.org/docs/zuul/user/howtos/pti.html
