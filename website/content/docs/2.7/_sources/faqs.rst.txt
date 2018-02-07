.. toctree::

Frequently Asked Questions
==========================

What is the added value of Software Factory ?
.............................................

If you are not sure about using Software Factory, here are some perks that might
convince you:

* Software Factory is a Continuous Integration system that works out of the box, with everything ready to be used right after the first configuration run.
  Deploying all the services by hand and with this level of interdependency would take a lot more time.
* Software Factory helps enforcing the latest best practices in Continuous Integration.
* In Software Factory, the configuration is treated as code that can therefore be versioned, reviewed, tested or rolled back for any change.
* Users are automatically and consistently authenticated on each service with Single Sign-On. Again, achieving this by hand would be very time consuming.
* Software Factory can be fully backed up, restored, and upgraded automatically through tested processes.
* Software Factory can be deployed anywhere: baremetal systems, LXC, KVM or on OpenStack via Heat.
* Software Factory is fast to deploy (3/5 minutes on a local system, 15 minutes with Heat).
* Software Factory runs worker nodes on demand on an OpenStack cloud, which can reduce effective costs of testing.


Can I disable Gerrit ?
......................

As of now, Gerrit is mandatory in Software Factory for a couple of reasons:

* Managesf access control policies are based on Gerrit groups.
* The config repository is hosted on Gerrit with an integrated CI/CD workflow.

Gerrit will be made optional in a future release [1]_ of Software Factory

Note that it is possible to use Software Factory as a third party CI for
an external Gerrit or a GitHub organization. In this case, the gerrit server
is only used to host the config repository, and operators can bypass it
entirely by pushing config repository changes with the "git push" command
instead of "git review".

.. [1] To be determined

Why can't I +2 a change after being added to the core group ?
.............................................................

This may happen because of web browser cache issues. Remove all
cookies then log out and log in again to refresh your gerrit privileges.


Why does my build fail with the "NOT_REGISTERED" error ?
........................................................

This error happens when zuul can't build a job. Most of the time it's because:

* A project gate is configured with an unknown job. The job's definition
  is likely missing in zuul's layout.
* No worker node was ever available. Zuul will fail throwing a NOT_REGISTERED error
  (instead of queuing) until a worker node with the correct label is available.
  Only then, once Zuul knows a label really exists, will it properly queue builds.

The first step to investigate that error is to verify that the job is present
in the jobs dashboard. If the job is not there, check the config repository and check
that the job is either expanded from a job template (using the project's name),
or that is fully defined. Otherwise add the job and update the config repository.


Why does my build stay in "queued" state ?
..........................................

This happens when no worker nodes are available to execute a build:

* First verify that at least one worker node with the right label exists. You can list nodes
  with the sfmanager CLI.
* Then verify that your job definition actually uses the right worker node label.


How can I change my deployment's hostname?
..........................................

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


How to setup a mirror on swift for external dependencies ?
..........................................................

The mirror service uses the mirror2swift utility to provide a local cache
for external ressources. For example we use it to mirror RPM repositories,
which speeds up building times of our test environments.

To enable the mirror service, you need to configure a swift container
in sfconfig.yaml and then specify the URL to mirror in the config-repo:

* Add the **mirror** role to /etc/software-factory/arch.yaml
* Configure the mirror role in /etc/software-factory/sfconfig.yaml
* Run sfconfig
* Edit the mirror configuration template provided in the *mirrors* directory of
  the config repository.

When **periodic_update** is set, the mirror will be updated periodically
through a dedicated zuul pipeline. The status of the update can be checked like any
other CI build. Otherwise, to update the cache manually, this command needs to be
executed:

.. code-block:: bash

    sudo -u mirror2swift mirror2swift /var/lib/mirror2swift/config.yaml


sfconfig.yaml example:

.. code-block:: yaml

  mirrors:
    periodic_update: '0 0 * * \*'
    swift_mirror_url: http://swift:8080/v1/AUTH_uuid/repomirror/
    swift_mirror_tempurl_key: TEMP_URL_KEY

The swift_mirror_url needs to be the canonical, fully qualified url of the target container.
The swift_mirror_tempurl_key needs to be a tempurl key with writing rights.
The periodic_update needs to be a valid zuul timer format, e.g. daily is '0 0 * * \*'.

The yaml files in the config repository represent the list of mirrors as documented here:
https://github.com/cschwede/mirror2swift. For example, config/mirrors/centos.yaml:

.. code-block:: yaml

  - name: os
    type: repodata
    url: 'http://centos.mirror.example.com/7/os/x86_64/'
    prefix: 'os/'

This will mirror the CentOS-7 base repository to http://swift:8080/v1/AUTH_uuid/repomirror/os/


How to restart zuul without losing builds in progress ?
.......................................................

The zuul service is stateless and stopping the process will lose track
of running jobs. However the zuul-changes.py utility can be used
to save and restore the current state:

.. code-block:: bash

    # Print and save all builds in progress to /var/lib/zuul/zuul-queues-dump.sh
    /usr/share/sf-config/scripts/zuul-changes.py dump

    systemctl restart zuul-server

    # Reload the previous state:
    /usr/share/sf-config/scripts/zuul-changes.py load

The periodic and post pipelines are not dumped by this tool.


.. _gerrit-rest-api:

How can I use the Gerrit REST API?
..................................

The Gerrit REST API is open for queries by default on all Software Factory deployments.
There is an extensive documentation available online:

  https://gerrit-review.googlesource.com/Documentation/rest-api.html

To use the Gerrit REST API in Software Factory, you have to create an API
password first. To do so, go to the **User Settings** page (upper right corner on the top menu)
and click the Enable button for "Gerrit API key".

The Gerrit API is available at the following endpoint:

  https://fqdn/api/

and for authenticated requests, using the API password:

  https://fqdn/api/a/

For example, getting open, watched changes on the default deployment with cURL would be:

  curl -X GET http://sftests.com/api/changes/?q=status:open+is:watched&n=2

You can find a full working example to automate some tasks (in this case deleting a specific branch
on a list of projects) in `tools/deletebranches.py`.


How can I use Gertty?
.....................

After getting a Gerrit API key (as explained :ref:`above <gerrit-rest-api>`), use
the *basic* auth-type in gertty.yaml, e.g.:

.. code-block:: yaml

    servers:
      - name: sftests
        url: https://sftests.com/api/
        git-url: ssh://USER_NAME@sftests.com:29418
        auth-type: basic
        username: USER_NAME
        password: API_KEY
        git-root: ~/git/
