.. _how_to_contribute:

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
