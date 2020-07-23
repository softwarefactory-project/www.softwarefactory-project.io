Zuul Security Fix Localhost
###########################

:date: 2020-07-22 00:00
:modified: 2020-07-22 00:00
:category: blog
:authors: sf

A new Zuul version has been added to the SF-3.4 to address
a security issue: `https://review.opendev.org/742229 <https://review.opendev.org/742229>`_.
To fix a deployment run **sfconfig --update** from the
install-server. Alternatively, run:

.. code-block:: bash

   # From the install-server
   ansible -m command -a "yum update -y *zuul*" zuul-scheduler:zuul-web:zuul-executor:zuul-merger
   ansible-playbook /var/lib/software-factory/ansible/zuul_restart.yml
