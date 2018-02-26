=========================
Contributor documentation
=========================


How can I help?
---------------

Thanks for asking.

The easiest way to get involved is to join us on IRC. We hang out on the #softwarefactory channel on Freenode.

To join technical discussions or get announcements, subscribe to our mailing list softwarefactory-dev@redhat.com: https://www.redhat.com/mailman/listinfo/softwarefactory-dev.

The project's backlog is here: https://tree.taiga.io/project/morucci-software-factory/backlog?tags=software%20factory

And issues can be reported here: https://tree.taiga.io/project/morucci-software-factory/issues .

Prepare a development environment
---------------------------------

Software Factory runs and is developed on CentOS 7. Provision a CentOS 7 system, then install the following prerequisites:

.. code-block:: bash

 sudo yum install -y centos-release-openstack-pike
 sudo yum install -y git git-review vim-enhanced tmux curl rpmdevtools createrepo mock python-jinja2 ansible
 sudo /usr/sbin/usermod -a -G mock $USER
 newgrp mock

It is recommended that your Centos 7 installation be dedicated to Software Factory development
to avoid conflicts with unrelated components.

Then you will need to check out the Software Factory repositories:

.. code-block:: bash

 mkdir software-factory scl
 git clone https://softwarefactory-project.io/r/software-factory/sfinfo software-factory/sfinfo
 git clone https://softwarefactory-project.io/r/software-factory/sf-ci
 ln -s software-factory/sfinfo/zuul_rpm_build.py .
 ln -s software-factory/sfinfo/sf-master.yaml distro.yaml

The file *sfinfo/sf-master.yaml* contains the references of all the repositories that form
the Software Factory distribution.

Rebuilding packages
-------------------

Each component of Software Factory is distributed via a package and as a contributor you may
need to rebuild a package. You will find most RPM package definitions in
<component>-distgit repositories and sources in <component> repositories.

Here is an example to rebuild the Zuul package.

.. code-block:: bash

 ./zuul_rpm_build.py --project scl/zuul

Newly built packages are available in the zuul-rpm-build directory.

Use the "--noclean" argument to speed the process up. This argument prevents
the mock environment from being destroyed and rebuilt, but does not clean the
zuul-rpm-build directory so you might want to clean it first.

.. code-block:: bash

 rm -Rf ./zuul-rpm-build/* && ./zuul_rpm_build.py --noclean --project scl/zuul

Multiple packages can be specified to trigger their builds.

.. code-block:: bash

 rm -Rf ./zuul-rpm-build/* && ./zuul_rpm_build.py --noclean --project scl/zuul --project scl/nodepool

How to run the tests
--------------------

Software Factory's functional tests live in the sf-ci repository. You should use the run_tests.sh
script as an entry point to run test scenarios.

Deployment test
...............

.. code-block:: bash

 cd sf-ci
 ./run_tests.sh deploy minimal

This will run the *deploy* ansible playbook with the *minimal* architecture
of Software Factory. The *allinone* architecture can be specified too.

The *deploy* playbook installs the latest development version of Software Factory.
This is the recommended way to start with sf-ci. If the *deploy* scenario fails
please notify us directly on IRC or create a bug report on our tracker.

This scenario completes in about 15 minutes.

If you want to use locally built packages then you can prefix the run_tests.sh command
with the LOCAL_REPO_PATH=$(pwd)/../zuul-rpm-build:

.. code-block:: bash

 LOCAL_REPO_PATH=$(pwd)/../zuul-rpm-build ./run_tests.sh deploy minimal

To test small changes, it's also possible to install the code directly in place,
for example:

* sf-config repository content can be rsynced to /usr/share/sf-config
* managesf can be installed using "python setup.py install"

Access to SF's UI
.................

After a successful run of run_tests.sh the UI is accessible
via a web browser. The default hostname of a deployment is *sftests.com*
so you should be able to access it using *http(s)://sftests.com*.

As sftests.com domain might be not resolvable it needs to be added to
your host resolver:

.. code-block:: bash

 echo "<sf-ip> sftests.com" | sudo tee -a /etc/hosts

Local authentication is enabled for the *admin* user using the
password *userpass*. Some more unprivileged test users are available:
*user2*, *user3*, *user4* with the password *userpass*.

Please note that the *Toogle login form* link must be clicked in order to
display the login form.

Scratch a deployment
....................

To scratch a deployment and start over, use the "--erase" argument:

.. code-block:: bash

 sudo sfconfig --erase

This command erases all data from the current deployment and uninstalls most of the
Software Factory packages. It is recommended to start working on new features or
bug fixes on a clean environment.

When switching from a *minimal* deployment to an *allinone* it is advised
to run that command beforehand to avoid some side effects during functional tests.


Functional tests
................

The *functional* scenario extends the *deploy* scenario by:

* Provisioning random data (Git repos, reviews, stories, ...)
* Get a backup
* Run health-check playbooks (see sf-ci/health-check/)
* Run functional tests (see sf-ci/tests/functional/)
* Check firefose events
* Erase data (sfconfig --erase)
* Recover the data from the backup (sfconfig --recover)
* Check that provisioned data have been recovered

.. code-block:: bash

 ./run_tests.sh functional allinone

Note that you can use LOCAL_REPO_PATH to include your changes.

This scenario completes in about 60 minutes.

Upgrade test
............

The *upgrade* scenario simulates an upgrade from the last released version
of Software Factory to the current development version.

The scenario runs like this:

* Install and deploy the latest release of Software Factory
* Provision data
* Upgrade the instance to the current development version
* Check the provisioned data
* Run heath-check playbooks
* Run functional tests

.. code-block:: bash

 ./run_tests.sh upgrade allinone

Note that you can use LOCAL_REPO_PATH to include your changes.

This scenario completes in about 60 minutes.

Functional tests
................

After having deployed Software Factory using sf-ci, run:

.. code-block:: bash

 sudo ./scripts/create_ns.sh nosetests -sv tests/functional/

Most tests can be executed without the *create_ns.sh* script but some
of them require to be wrapped inside a network namespace to simulate
external remote access to the Software Factory gateway.

Tips:

* you can use file globs to select specific tests: [...]/tests/functional/\*zuul\*
* **-s** enables using 'import pdb; pdb.set_trace()' within a test
* Within a test insert 'from nose.tools import set_trace; set_trace()' to add a breakpoint in nosetests
* **--no-byte-compile** makes sure no .pyc are run

Health-check playbooks
......................

After having deployed Software Factory using sf-ci, run:

.. code-block:: bash

 sudo ansible-playbook health-check/sf-health-check.yaml

The health-check playbooks complete the functional tests
coverage by testing:

* Zuul
* Gerritbot

Testinfra validation
....................

After having deployed Software Factory using sf-ci, run:

.. code-block:: bash

 sudo testinfra /usr/share/sf-config/testinfra

The testinfra checks are simple smoke tests validating Software Factory's
services are up and running.

Configuration script
--------------------

After having deployed Software Factory using sf-ci, run:

.. code-block:: bash

 sudo sfconfig

Using ARA to inspect SF playbooks runs
--------------------------------------

Installation
............

ARA provides a web interface to inspect Ansible playbook runs like the health-check
tests. Using it during development is a good idea. Here are the steps to install it:

.. code-block:: bash

 sudo yum install https://softwarefactory-project.io/repos/sf-release-2.6.rpm
 sudo yum install ara
 sudo yum remove sf-release-2.6.0

If you already installed the sf-release package (will be the case if sf-ci
*run_tests.sh* script ran before) then you might need to run *yum downgrade*
instead.

Prepare the environment variables for ARA
.........................................

The *run_tests.sh* script handles that for you but in case you want to run
commands directly without this script, you must export the following
variables to configure ARA callbacks in Ansible:

.. code-block:: bash

 export ara_location=$(python -c "import os,ara; print(os.path.dirname(ara.__file__))")
 export ANSIBLE_CALLBACK_PLUGINS=$ara_location/plugins/callbacks
 export ANSIBLE_ACTION_PLUGINS=$ara_location/plugins/actions
 export ANSIBLE_LIBRARY=$ara_location/plugins/modules

User Interface
..............

.. code-block:: bash

 ara-manage runserver -h 0.0.0.0 -p 55666

Then connect to http://sftests.com:55666

Software Factory CI
-------------------

Changes submitted to Software Factory's repositories will be tested on the
Software Factory upstream CI by building the following jobs:

* sf-rpm-build (build RPMs if needed by the change)
* sf-ci-functional-minimal (run_tests.sh functional minimal)
* sf-ci-upgrade-minimal (run_tests.sh upgrade minimal)
* sf-ci-functional-allinone (run_tests.sh functional allinone)
* sf-ci-upgrade-allinone (run_tests.sh upgrade allinone)

The Software Factory upstream CI is based on sf-ci too, so the outcome of the
upstream tests should reflect accurately the results of the tests you would run
locally.

How to contribute
-----------------

* Connect to https://softwarefactory-project.io/ to create an account
* Register your public SSH key on your account. See: :ref:`Adding public key`
* Check the bug tracker and the pending reviews

Submit a change
...............

.. code-block:: bash

  git-review -s # only relevant the first time to init the git remote
  git checkout -b"my-branch"
  # Hack the code, create a commit on top of HEAD ! and ...
  git review # Summit your proposal on softwarefactory-project.io

Your patch will be listed on the reviews dashboard at https://softwarefactory-project.io/r/ .
Automatic tests are run against it and the CI will
report results on your patch's summary page. You can
also check https://softwarefactory-project.io/zuul/ to check where your patch is in the pipelines.

Note that Software Factory is developed using Software Factory. That means that you can
contribute to Software Factory in the same way you would contribute to any other project hosted
on an instance: :ref:`contribute`.
