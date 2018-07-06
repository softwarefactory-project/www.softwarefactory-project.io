.. _inspect_with_ara:

Using ARA to inspect SF playbooks runs
--------------------------------------

Installation
............

ARA provides a web interface to inspect Ansible playbook runs like the health-check
tests. Using it during development is a good idea. Here are the steps to install it:

.. code-block:: bash

 sudo yum install https://softwarefactory-project.io/repos/sf-release-2.6.rpm
 sudo yum install ara
 sudo yum remove sf-release-2.6.0

If you already installed the sf-release package (will be the case if sf-ci
*run_tests.sh* script ran before) then you might need to run *yum downgrade*
instead.

Prepare the environment variables for ARA
.........................................

The *run_tests.sh* script handles that for you but in case you want to run
commands directly without this script, you must export the following
variables to configure ARA callbacks in Ansible:

.. code-block:: bash

 export ara_location=$(python -c "import os,ara; print(os.path.dirname(ara.__file__))")
 export ANSIBLE_CALLBACK_PLUGINS=$ara_location/plugins/callbacks
 export ANSIBLE_ACTION_PLUGINS=$ara_location/plugins/actions
 export ANSIBLE_LIBRARY=$ara_location/plugins/modules

User Interface
..............

.. code-block:: bash

 ara-manage runserver -h 0.0.0.0 -p 55666

Then connect to http://sftests.com:55666
