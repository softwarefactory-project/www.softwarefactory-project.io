.. _pages-operator:

Pages service for hosting static WEB content
============================================

Software Factory enables a workflow for publishing static WEB content.

Below is the list of supported source type:

 * Static contents (HTML/JS/CSS) with an index.html
 * Pelican source (https://blog.getpelican.com)

How to activate
---------------

This component is not deployed by default but can be activated by adding
it in */etc/software-factory/arch.yaml*:

.. code-block:: yaml

 - pages

Then running:

.. code-block:: bash

 # sfconfig

Domain configuration
--------------------

Publications will be accessible via *http(s)://<name>.<sfdomain>* and
handled by the Software Factory gateway as virtual hosts. In the
DNS configuration a wildcard must be setup to redirect every subdomains
to the Software Factory gateway IP.

Pages usage
-----------

Please refer to `Publish static WEB content <pages-user>`.
