Zuul Security Fix Ansible plugin loading
########################################

:date: 2022-03-25 00:00
:modified: 2022-03-25 00:00
:category: blog
:authors: sf

A new Zuul version has been added to the SF-3.6 to address
a security issue: `https://review.opendev.org/835121 <https://review.opendev.org/835121>`_.
To fix a deployment run **sfconfig --update** from the
install-server. Alternatively, run:

.. code-block:: bash

   # From the install-server
   ansible -m command -a "yum update -y *zuul*" zuul-scheduler:zuul-web:zuul-executor:zuul-merger
   ansible-playbook /var/lib/software-factory/ansible/zuul_restart.yml
