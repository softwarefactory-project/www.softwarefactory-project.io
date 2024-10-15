.. _resources-user:

Managing resources via the config repository
============================================

Software Factory manages user groups, git repositories, Gerrit ACLs, and projects
via the **config** repository. The config repository has its own CI and CD pipelines,
automatically set up on Software Factory.

.. note::

   Project, repository and ACL management across all services is only supported
   on Gerrit.

Advantages of managing resources via the config repository
----------------------------------------------------------

Resources are described using a strict YAML format that will reflect
the current state of the resources on the services. For instance
a group described in YAML will be created and provisioned with the
specified users on Gerrit. Any modification on the group
will be reflected on Gerrit. So looking at the YAML files you'll
see the real state of Software Factory services like Gerrit.

Furthermore using this config repository leverages the review workflow
through Gerrit so that any modification on a resource requires
a human review before being applied to the services. Finally
all modifications can be tracked and audited through the repository's version history.

A Software Factory operator will just need to approve a resource change and let
the **config-update** job apply the changes on the services.

How it works
------------

The config repository is populated by default with a **resources** directory.
All YAML files under that directory that follow the expected format are loaded and taken into
account.

For example the following YAML file describes a group called *mygroup*:

.. code-block:: yaml

  resources:
    groups:
      mygroup:
        members:
          - me@domain.com
          - you@domain.com
        description: This is the group mygroup

This file must be named with the extension .yml or .yaml under
the resources directory of the config repository.

Once done:

* The default *config-check* job will be run and validate this new resource.
* The CI will assign a score to the *Verified* label.
* Everyone with access to the platform can comment and vote.
* Privileged users can approve the change.
* Once approved and merged, the *config-update* job will take care
  of creating the group on services like Gerrit.

.. _project-example:

A more complete example
-----------------------

Below is a YAML file that can be used as a starting point:

.. code-block:: yaml

  resources:
    projects:
      ichiban-cloud:
        tenant: local
        description: The best cloud platform engine
        contacts:
          - contacts@ichiban-cloud.io
        source-repositories:
          - ichiban-config:
              zuul/config-project: True
          - ichiban-compute
          - ichiban-storage
        website: http://ichiban-cloud.io
        documentation: http://ichiban-cloud.io/docs
        issue-tracker-url: http://ichiban-cloud.bugtrackers.io
    repos:
      ichiban-config:
        description: The config project of ichiban-cloud
        acl: ichiban-dev-acl
      ichiban-compute:
        description: The compute manager of ichiban-cloud
        acl: ichiban-dev-acl
      ichiban-storage:
        description: The storage manager of ichiban-cloud
        acl: ichiban-dev-acl
    acls:
      ichiban-dev-acl:
        file: |
          [access "refs/*"]
            read = group ichiban-core
            owner = group ichiban-ptl
          [access "refs/heads/*"]
            label-Code-Review = -2..+2 group ichiban-core
            label-Code-Review = -2..+2 group ichiban-ptl
            label-Verified = -2..+2 group ichiban-ptl
            label-Workflow = -1..+1 group ichiban-core
            label-Workflow = -1..+1 group ichiban-ptl
            label-Workflow = -1..+0 group Registered Users
            submit = group ichiban-ptl
            read = group ichiban-core
            read = group Registered Users
          [access "refs/meta/config"]
            read = group ichiban-core
            read = group Registered Users
          [receive]
            requireChangeId = true
          [submit]
            mergeContent = false
            action = fast forward only
        groups:
          - ichiban-ptl
          - ichiban-core
    groups:
      ichiban-ptl:
        members:
          - john@ichiban-cloud.io
          - randal@ichiban-cloud.io
        description: Project Techincal Leaders of ichiban-cloud
      ichiban-core:
        members:
          - eva@ichiban-cloud.io
          - marco@ichiban-cloud.io
        description: Project Core of ichiban-cloud


.. Note::

   Users mentioned in a group must have been logged at least once on Software Factory.

Refer to the `resources schema documentation </docs/managesf/resources.html>`_ for
more information about resources definition.

Deleting a resource is as simple as removing it from the resources YAML files.
Updating a resource is as simple as updating it in the resources YAML files.

Keys under each resources' groups are used to create and reference (as
unique id) real resources into services. So if you want to rename a resource
you will see that the resource is detected as "Deleted" and a new one will
be detected as "Created". If you intend to do that with a repository resource then
you have to make sure you have fetched locally your git repository's branches because
the git repository is going to be deleted on Software Factory and created under the new name.

Resource deletion
-----------------

When modifications to the resources tree include the deletion of a resource, the verification
job "config-check" will return a failure if the commit message of the change
does not include the string "sf-resources: allow-delete". This can be seen
as a confirmation from the change's author to be sure the the deletion of some resources
is actually intended.

.. _zuul-resources-integration:

Integration with Zuul
---------------------

Zuul requires a tenants configuration file to be aware of the repositories it needs
to watch for events. Software Factory can generate the tenant configuration from the
resources.

By default, the *source-repositories* attached to a project, like below, are added
automatically to Zuul as *untrusted-projects*:

.. code-block:: yaml

  resources:
    projects:
      ichiban-cloud:
        tenant: local
        description: The best cloud platform engine
        source-repositories:
          - ichiban-compute
          - ichiban-storage

    repos:
      ichiban-compute:
        description: The compute manager of ichiban-cloud
        acl: ichiban-dev-acl
      ichiban-storage:
        description: The storage manager of ichiban-cloud
        acl: ichiban-dev-acl

To define a specific configuration for a repository (a project in the
Zuul terminology), for instance, a *source-repositorie* can be defined
as a *config-project*:

.. code-block:: yaml

  source-repositories:
    - ichiban-config:
        zuul/config-project: True
    - ichiban-compute
    - ichiban-storage

Other zuul configuration options can be added using the *zuul/* prefix:

.. code-block:: yaml

  source-repositories:
    - ichiban-config:
        zuul/include:
          - job
        zuul/shadow: common-config

All repositories are attached to Zuul
.....................................

Repositories that are not attached to a project's source-repository list are
automatically added to the Zuul configuration using the *include: []* option
to make Zuul ignore the in-repo configuration. This steps is referred to as
adding the "missing resources".

To exclude a *source-repository* from Zuul configuration:

.. code-block:: yaml

  source-repositories:
    - ichiban-compute:
        zuul/ignore: True


.. _zuul-github-resources:

Define a github project in the resources
----------------------------------------

.. code-block:: yaml

  resources:
    projects:
      repopo:
        description: "The repopo project"
        connection: github.com
        source-repositories:
          - org/repopo1:
              zuul/exclude-unprotected-branches: true
