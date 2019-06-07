.. _gerrit-replication-user:

Configure Gerrit git repositories replication
=============================================

Introduction
------------

Software Factory can replicate git repositories to remote git servers.
This feature relies on Gerrit's replication plugin.

The replication settings can be changed in the config repository; they can be found in the directory
"gerrit" you will find a file called replication.config.

The replication of repositories should be done using the SSH protocol.
By default Software Factory will use its own SSH private key to
authenticate against the remote server.


Configure the replication for a repository
------------------------------------------

As a project's maintainer, I want to setup the replication of my repositories
*myproject-client* and *myproject-server* to a remote server. So I have to submit
a patch to the config repository.

Clone the config repository:

.. code-block:: bash

 $ git clone https://<fqdn>/r/config

Edit the file *gerrit/replication.config* and add the following::

 [remote "example-mirror"]
     url = sf@mirrors.domain.example:/home/mirror/git/${name}.git
     mirror = true
     projects = ^myproject-.*

Here we configure the replication to replicate repositories
where names match the regular expression "^myproject-.*" to the remote
server mirrors.domain.example. The special placeholder "${name}" is needed here
because the regular expression will match several repositories. The "mirror" option is
set to *true* to replicate branch deletion.

.. note::

  Software Factory's replication support is based on Gerrit's own replication plugin.
  More information on available options can be found in the
  `Replication README <https://softwarefactory-project.io/r/plugins/replication/Documentation/config.html>`_.

Then commit and send the patch for review.

.. code-block:: bash

 $ git commit -m'Add replication for myproject suite'
 $ git review

Once the patch is merged the *config-update* job will trigger the replication
to mirrors.domain.example (in that example).

.. note::

  The public key used for the replication needs to be added to
  the *.ssh/authorized_keys* of the sf user on mirrors.domain.example.


See the :ref:`Gerrit replication operator documentation<gerrit-replication-operator>`

.. note::

  If mirrors.domain.example has never been used as a replication
  target, then the Software Factory administrator should add the server's
  host key to the known_hosts file on Software Factory's Gerrit node.

.. note::

  There is no need to create the bare git repository on the
  remote server as long as a regular shell is available on the target. The
  replication plugin will create the repository if it does not exist.


Get the replication SSH public key
----------------------------------

Gerrit SSH public key is available at the following URL.

.. code-block:: bash

  $ curl -OL https://<fqdn>/keys/gerrit_service_rsa.pub

Configuring repository replication on Github
--------------------------------------------

There are two solutions you may use to replicate on Github:

 * Define a deployment key in your github repository's settings
 * Add a collaborator to your github repository's settings

The former is less straigtforward than the latter, and involve more work from the
Software Factory administrator, because the replication plugin will by default use its
own key to authenticate against Github. However each deployment key on GitHub
must be unique so you will have to create a key pair and request your
Software Factory administrator to add the private key on Software Factory.

The latter does not require any specific configuration from
the Software Factory administrator. As a Github project owner you should add a
collaborator, and register the Software Factory public key in the "SSH key" section of the
Github user settings. Software Factory will then act on behalf of that Github user for
the replication. Please ask your Software Factory administrator if a specific user
on Github already exists for replication purposes.

.. note::

  Software Factory won't create repositories on Github if they do not exist. They
  must be created manually.
