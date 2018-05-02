Version 3.0 updates
###################

:date: 2018-05-02 18:40
:modified: 2018-05-02 18:40
:category: blog
:authors: Tristan Cacqueray

The software factory version 3.0 has been updated with the latest Zuul version.
As usual, to update the deployment, run this commands:

.. code-block:: bash

  sudo yum update -y && sudo sfconfig

The Zuul version 3.0.2 is now using regular expression for GitHub
status requirements, and matches may failed when using regexp token. For example:

.. code-block:: yaml

  - pipeline:
      name: gate
      requires:
        github:
          status: "zuul-app[bot]:local/check:success"

This needs to be adapted to: "zuul-app\\[bot\\]:local/check:success".

Note that automatic gate pipelines setup for Github will be available in the
version 3.1 of Software Factory.
