Installation
############

:date: 2018-02-07 19:30
:modified: 2018-02-07 19:30
:slug: install
:authors: Fabien Boucher


Prerequisites
-------------

Software Factory requires CentOS 7 as its base Operating System so the commands listed below
should be executed on a fresh deployment of CentOS 7. The default FQDN of a Software Factory
deployment is sftests.com. In order to be accessible in your browser, sftests.com must be
added to your /etc/hosts with the IP address of your deployment.


Installation
------------

First, let’s install the repository of the last version then install sf-config, the configuration management tool.

.. code-block:: bash

 sudo yum install -y https://softwarefactory-project.io/repos/sf-release-2.7.rpm
 sudo yum install -y sf-config


Starting the services
---------------------

Finally run sf-config:

.. code-block:: bash

 sudo sfconfig

When the sf-config command finishes you should be able to access the Software Factory web UI by
connecting your browser to https://sftests.com. You should then be able to login using the login
admin and password userpass (Click on "Toggle login form" to display the built-in authentication).

For more detailed instruction, please read the Sofware Factory `documentation`_.

.. _`documentation`: https://softwarefactory-project.io/docs/
