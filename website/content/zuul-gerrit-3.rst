Zuul Update for Gerrit 3.x
##########################

:date: 2020-12-01 00:00
:modified: 2020-12-01 00:00
:category: blog
:authors: sf

A Zuul fix has been added to the version 3.5 of SF to address a performance issue
when using Gerrit version 3.x has reported by the opendev infrastructure team.
To fix a deployment run **sfconfig --update** from the install-server.
Alternatively, to avoid going through CentOS 7.9 packages:

.. code-block:: bash

   # From the install-server
   ansible -m command -a "yum update -y rh-python35-zuul*" install-server:zuul-scheduler:zuul-merger:zuul-executor
   ansible-playbook /var/lib/software-factory/ansible/zuul_restart.yml
