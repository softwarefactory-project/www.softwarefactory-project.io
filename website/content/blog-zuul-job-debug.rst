Debug/quickstart new zuul jobs with auto-hold
#############################################

:date: 2018-10-26
:category: blog
:authors: tristanC

This article demonstrates an easy way to debug and/or quickstart a new Zuul jobs
using the auto hold feature and local job execution.


Create an initial job
---------------------

The first step is to create a first job, for example, submit this
zuul.yaml file to a project named demo-project:

.. code-block:: yaml

   # demo-project/zuul.yaml
   ---
   - job:
       name: demo-job
       run: playbooks/demo.yaml
       nodeset:
         nodes:
           - name: controller
             label: centos-7

   - project:
       check:
         jobs:
           - demo-job


With a test playbook

.. code-block:: yaml

   # demo-project/playbooks/demo.yaml
   --
   - hosts: controller
     roles:
       - install-tool
       - run-my-test


Use auto-hold and access the test instance
------------------------------------------

From the Software Factory instance,
use this command to ask zuul to hold the node if the job failed:

.. code-block:: bash

   zuul autohold --tenant local --project demo-project --job demo-job --reason quickstart


Use this command to get node ip address

.. code-block:: bash

   nodepool list | grep hold


Then connect and add your ssh key

.. code-block:: bash

   ssh -i /var/lib/zuul/.ssh/id_rsa zuul@IP


Re-run the job locally
----------------------

On the test instance, go to src/<connection-name>/<project-name>/playbooks

Generate a fake inventory:

.. code-block:: ini

   # ./inventory
   [controller]
   localhost ansible_connection=local

Generate fake variables if needed (copy them from zuul-info/inventory.yaml
artifacts):

.. code-block:: yaml

   # ./vars.yaml
   zuul:
     project:
       name: demo-project
       src_dir: src/example.com/demo-project

Reproduce job locally:

.. code-block:: bash

   # Symlink used role location
   ln -s ../roles .
   ansible-playbook -i inventory -e @./vars.yaml demo.yaml
