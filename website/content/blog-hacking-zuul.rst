Hacking Zuul for developers
###########################

:date: 2022-07-01
:category: blog
:authors: mhuin

Zuul can be, honestly, quite an intimidating beast to handle. Running Zuul
itself requires setting up many satellite services like mariadb and zookeeper.
This might make it hard to quickly test small changes, or just tinker with the code base.

I will share some tips on how to experiment or play around with Zuul's code.

The regular way: Zuul CI
------------------------

When you are putting in the effort to modify Zuul's code base, chances are you would
like your change to eventually get merged into `the upstream repository <https://opendev.org/zuul/zuul>`_.
Then you are going to have to get a "Verified +1" review from Zuul's automated CI.

In that case, you might as well just run your tests in the upstream CI. The one major drawback
that I see with this, is that the feedback loop can be relatively long: the test suite
is quite exhaustive, and you are sharing testing resources with other developers from all
of Opendev. It is not rare to get feedback from the CI only one or two hours after having
pushed your change (and that's honestly not a bad performance at all).

A simple way to speed up the process is to limit your testing to the strict minimum:
linters and tox-py*. You could even drop the linters tests as they require very little
dependencies and can be run in your local dev environment even with limited resources:

.. code:: bash

  tox -elinters

Locate the `.zuul.yaml` file at the root of your local copy of the Zuul repository
and comment out the jobs you don't want to run like so:

.. code:: yaml

  - project:
      vars:
        node_version: 16
        release_python: python3
      check:
        jobs:
        #  - zuul-build-image
        #  - zuul-tox-docs
          - tox-linters:
              vars:
                tox_install_bindep: false
          - zuul-tox-py38
          - zuul-tox-py39
        #  - zuul-tox-py39-multi-scheduler
        #  - zuul-build-dashboard-openstack-whitelabel
        #  - zuul-build-dashboard-software-factory
        #  - zuul-build-dashboard-opendev
        #  - nodejs-run-lint:
        #      vars:
        #        zuul_work_dir: "{{ zuul.project.src_dir }}/web"
        #  - nodejs-run-test:
        #      vars:
        #        zuul_work_dir: "{{ zuul.project.src_dir }}/web"
        #      files:
        #        - web/.*
        #  - zuul-stream-functional-2.8
        #  - zuul-stream-functional-2.9
        #  - zuul-stream-functional-5
        #  - zuul-tox-remote
        #  - zuul-quick-start:
        #      requires: nodepool-container-image
        #      dependencies: zuul-build-image
        #  - zuul-tox-zuul-client
        #  - zuul-build-python-release

Don't forget however to uncomment these when your patch is ready for review; otherwise
it has no chance to get merged. :)

It would even be possible to limit the tox-py* job to run a given set of tests rather than the
full unit test suite, but I strongly recommend against doing that. This would risk hiding some
unexpected side effects.

The example compose
-------------------

`Zuul's documentation <https://zuul-ci.org/docs/zuul/latest/tutorials/quick-start.html>`_ provides
a very nifty Docker (or podman) `compose file <https://opendev.org/zuul/zuul/src/branch/master/doc/source/examples/docker-compose.yaml>`_.
with just: 

.. code:: bash

  cd doc/source/examples && podman-compose up

You end up with a gerrit service, and a fully operational Zuul with a tenant and a few projects
pre-configured, in just minutes. This makes it super simple to run some basic workflows on this setup. It is
even possible to start a `Keycloak server to add authentication <https://zuul-ci.org/docs/zuul/latest/tutorials/keycloak.html>`_!

But what I appreciate most is the ability to live-patch Zuul if you want to test some code immediately.
Since I don't want to modify the upstream compose file, I just "brutishly" copy the python code into the
service containers and restart them. Let's say I have modified the REST API (assuming I am still in the 
doc/source/examples directory) - replace `podman` with `docker` depending on what you use:

.. code:: bash

  podman cp ../../../zuul examples_web_1:/usr/local/lib/python3.8/site-packages/
  podman-compose restart web

And that's it! The web component is now running your modified code. You can check the service's logs
with:

.. code:: bash

  podman logs -f examples_web_1

When you are done playing, make sure to destroy your patched containers with `podman-compose down`
so that you start from a clean slate next time you deploy the compose.

GUI development
---------------

Setting up a development server is pretty easy by following `the upstream documentation. <https://zuul-ci.org/docs/zuul/latest/developer/javascript.html#development>`_
Especially useful is the ability to run the GUI against a Zuul REST server of my choosing;
if I want to use the web service from the example compose I would run:

.. code:: bash

  REACT_APP_ZUUL_API="http://localhost:9000/api/" yarn start

It is also totally possible to use softwarefactory-project.io's or Opendev's Zuul instance
this way; however you are likely to run into `CORS-related problems <https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS>`_ in your browser since
the "origin" header differs from the value allowed by the distant servers. This a security
measure to ensure malicious javascript code living on a third-party server cannot be accidentally
allowed to do nasty stuff, thus CORS shouldn't be disabled (and as far as I can tell, most browsers
will make it very hard to do so in order to discourage you).

You can circumvent this problem by using a CORS proxy. I have been using this one without any problem
so far whenever I want to see how my changes look with data from Opendev's Zuul:

.. code:: bash

  podman run -p 8000:8000 bulletmark/corsproxy 8000:zuul.opendev.org

Then launch the dev server:

.. code:: bash

  REACT_APP_ZUUL_API="http://localhost:8000/api/" yarn start

Conclusion
----------

This article presented a few ways to shorten the feedback loop when contributing to Zuul. It
is by no means exhaustive and I am sure there are other great ways to set up a dev environment
for the project. I'd love to hear about your own practices!