.. _pages-user:

Publish static web content
==========================

Software Factory provides default Zuul jobs to build and publish
static website content. A user can use them to publish websites on a
Software Factory instance that will be publicly accessible on
*http://<custom-name>.sftests.com/*.

The following static content type are supported:

 * raw
 * Sphinx
 * Pelican


Activate the build-pages job
----------------------------

The *build-pages* job is well suited to be triggered in the *check* pipeline.
It builds the website source. The job fails if a processing error
occurs. After a successful build, the built website is available in
the *pages* directory on the log server.

In *.zuul.yaml* add the following:

.. code-block:: yaml

 - project:
     name: myproject
     check:
       jobs:
         - build-pages

The *build-pages* job expects to find the source of the website
at the root of the repository. If the source is contained in a
specific directory then the var *scr_dir* must be updated.

.. code-block:: yaml

 - project:
     name: myproject
     check:
       jobs:
         - build-pages:
             vars:
                src_dir: website


Activate the build-and-publish-pages job
----------------------------------------

*build-and-publish-pages* is a base job that must be used as parent job
in your custom publishing job. This custom job should be triggered by
the *gate* or the *post* pipeline to build and then publish the website on the
Software Factory gateway.

The following code block give an example of the base job customization to
define in a yaml file under the *config* repository *zuul.d/*.

.. code-block:: yaml

 - job:
     name: myproject-build-and-publish-pages
     parent: build-and-publish-pages
     final: true
     vars:
       vhost_name: www-myproject
     allowed-projects:
       - myproject

*vhost_name* is the name of the Apache Virtual Host and that means the website
will be accessible at *http://www-myproject.sftests.com*. Furthermore, note that
*final* set to *true* and *allowed-projects* set to the project name that will use
that job are important options. Indeed it ensures that, only, *myproject* can
use this publication's job.

Once the custom job definition is merged, the project's *.zuul.yaml* can
be updated to publish during the *gate* pipeline.

.. code-block:: yaml

 - project:
     name: myproject
     check:
       jobs:
         - build-pages
     gate:
       jobs:
         - myproject-build-and-publish-pages

As an alternative, the publication job can be configured in the *post*
pipeline.

.. code-block:: yaml

 - project:
     name: myproject
     check:
       jobs:
         - build-pages
     gate:
       jobs:
         - build-pages
     post:
       jobs:
         - myproject-build-and-publish-pages

Then next commits merged on *myproject* will be built and published and
accessible via the Virtual Host name.

Hostname resolution
-------------------

The Software Factory instance's domain DNS configuration must be configured with a wildcard
for all subdomains to be redirected to the Software Factory gateway IP.
If you run a Software Factory in a test environment you might not have
a real DNS entry configured then you should setup your local resolver.

For exemple adding in /etc/hosts:

.. code-block:: bash

 echo "<SF IP> <custom-name>.sftests.com" | sudo tee -a /etc/hosts
