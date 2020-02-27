Zuul Security Fix Add Host
##########################

:date: 2020-02-27 00:00
:modified: 2020-02-27 00:00
:category: blog
:authors: sf

A new Zuul version has been added to the SF-3.3 and SF-3.4 to address
a security issue: `https://review.opendev.org/710287 <https://review.opendev.org/710287>`_.
To fix a deployment run **sfconfig --update** from the
install-server. Alternatively, run:

.. code-block:: bash

   # From the install-server
   ansible -m command -a "yum update -y *zuul*" install-server:zuul-scheduler:zuul-merger:zuul-executor
   ansible-playbook /var/lib/software-factory/ansible/zuul_restart.yml
