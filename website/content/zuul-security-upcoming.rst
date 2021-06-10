Upcoming Zuul Security Fix
##########################

:date: 2021-06-10 00:00
:category: blog
:authors: sf

An important Zuul security update is going to be available for the SF-3.6 release.
Make sure your deployment is up to date by running **sfconfig --update**.

Please check the upstream announcement: http://lists.zuul-ci.org/pipermail/zuul-discuss/2021-June/001634.html

On 2021-06-24 14:00:00 UTC,
the new zuul package will be published, make sure you turn off the service and perform another **sfconfig --update**.
To make the update faster, you can run:

.. code-block:: bash

   # From the install-server, update zuul:
   ansible -m command -a "yum update -y *zuul*" install-server:zuul-scheduler:zuul-merger:zuul-executor:zuul-web
   ansible-playbook /var/lib/software-factory/ansible/zuul_restart.yml


Note that we are not able to fix the Zuul version 3.19 of the SF-3.5 release, thus
the 3.5 version is now End of life. If you are using SF-3.5, update now to SF-3.6 using:

.. code-block:: bash

   # From the install-server, update from sf-3.5 to sf-3.6
   yum install -y https://softwarefactory-project.io/repos/sf-release-3.6.rpm
   yum update -y sf-config
   sfconfig --update

If you experience any difficulties, please don't hesistate to raise an issue.
