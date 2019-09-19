Zuul Security Fix
#################

:date: 2019-09-19 00:00
:modified: 2019-09-19 00:00
:category: blog
:authors: sf

A new Zuul version has been added to the SF-3.2 and SF-3.3 to address
a security issue. To fix a deployment run *sfconfig --update* from the
install-server. Alternatively, to avoid going through CentOS 7.7 packages:

.. code-block:: bash

   # From the install-server
   ansible -m command -a "yum update -y rh-python35-zuul*" install-server:zuul-scheduler:zuul-merger:zuul-executor
   ansible-playbook /var/lib/software-factory/ansible/zuul_restart.yml
