.. _sf_ci:

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
