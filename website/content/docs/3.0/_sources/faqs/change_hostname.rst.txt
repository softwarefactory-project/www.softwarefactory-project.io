.. _change_hostname:

How can I change my deployment's hostname?
------------------------------------------

You can change the hostname after the deployment by changing the fqdn parameter
in /etc/software-factory/sfconfig.yaml, removing the existing SSL certificates
(only required if running functional tests and using the default self-signed
certificates) and running sfconfig again:

.. code-block:: bash

    sed -i -e 's/fqdn:.*/fqdn: mynewhostname.com/g' /etc/software-factory/sfconfig.yaml
    sfconfig

Please note that you might need to update URLs in other places as well, for
example git remote urls in .gitreview and .git/config files for repositories
hosted on Software Factory.
