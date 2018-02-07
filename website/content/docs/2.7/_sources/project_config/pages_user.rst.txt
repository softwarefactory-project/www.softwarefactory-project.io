:orphan:

.. note::

   This role isn't compatible with zuulv3

.. _pages-user:

Publish static web content
==========================

See :ref:`Pages service for hosting static web content <pages-operator>` for
more informations about the service.

Create the source repository
----------------------------

Software Factory detects publication repositories named *<name>.<sfdomain>* and
handles them as special repositories that contain content to be published.

For example, let's assume the Sofware Factory instance you are using is accessible
via the hostname *sftests.com* and you want to host content at *myproject.sftests.com*;
then simply create the repository *myproject.sftests.com*. The repository's name determines
whether it is a publication repository and its URL.

Please refer to this :ref:`section <resources-user>` for instructions on creating
repositories.

Publish content
---------------

The Git repository can be populated with raw content or pelican (https://blog.getpelican.com) sources.

Behind the scene Software Factory attaches two CI jobs to publication repositories:

 * pages-render (triggered by the check and gate pipelines)
 * pages-update (triggered by the post pipeline)

The *pages-render* job detects the content type and runs some content check.
Actually only pelican content is checked. The source is processed
by the job thus any mistakes detected by pelican will generate a
negative feedback note on the code review service.

Both jobs detect pelican content by testing if the file *pelicanconf.py*
exists at the root of the repository.

The *pages-update* job renders content if needed (for pelican content) and publishes it.
It runs in the *post* pipeline meaning that the run occurs once the code is merged
in the Git repository.

As soon as the code is merged and the job is finished then the content is accessible
under *http(s)://<repo-name>*.

Hostname resolution
-------------------

The Software Factory instance's domain DNS configuration must be configured with a wildcard
for all subdomains to be redirected to the Software Factory gateway IP.
If you run a Software Factory in a test environment you might not have
a real DNS entry configured then you should setup your local resolver.

For exemple adding in /etc/hosts:

.. code-block:: bash

 echo "<SF IP> <repo-name>" | sudo tee -a /etc/hosts
