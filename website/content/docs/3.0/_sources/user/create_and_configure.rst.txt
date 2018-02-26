.. _create_and_configure:

Create and configure a new project
----------------------------------

Creating a new project or repository is done by submitting a change on the
:ref:`Config repository <config-repo>`. This repository is a regular project,
see the :ref:`next chapter <contribute>` about how to contribute to a project.

To create and/or configure a project, you need to create a new review on the config
repository. The change consists of two parts:

 * Create the git repository/ies and ACL(s), see :ref:`this example<project-example>`
 * Add the project to the CI system, see :ref:`Zuul main.yaml<zuul-main-yaml>`.

In short, in a single change, the following files need to be created:

 * resources/new-project.yaml
 * zuul/new-project.yaml

Once the change is approved and merged, the project will be created/updated by
the config-update job.
