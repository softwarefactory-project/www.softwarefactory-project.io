Software Factory 3.2 New Update For Zuul Security Fix
#####################################################

:date: 2019-03-12 00:00
:modified: 2019-03-12 00:00
:category: blog
:authors: tristanC

The Software Factory version 3.2 has been updated to include the
latest Zuul release in order to fix a security issue. Patch your
deployment by running on the install-server:

.. code-block:: bash

   yum update -y sf-config && sfconfig --update
