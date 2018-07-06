.. _run_tests:

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
