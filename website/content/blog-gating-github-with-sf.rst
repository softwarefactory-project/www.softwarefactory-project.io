Gating projects on GitHub using Zuul
####################################

:date: 2019-02-06
:category: blog
:authors: Javier Peña

Introduction
============

Zuul is a very versatile tool for Continuous Integration. When used as part of
a Software Factory deployment, it is configured by default to gate new commits
to the integrated (but optional) Gerrit instance, however it can be configured
to do much more than that.

In this post, we will describe how we have configured Zuul to test changes to a
project hosted on GitHub.


What we wanted to achieve
=========================

The `ceph-ansible project <https://github.com/ceph/ceph-ansible/>`_ provides a
set of Ansible playbooks for Ceph, the distributed filesystem. These playbooks
are used by a number of projects, including `TripleO <http://tripleo.org/>`_,
an OpenStack project aimed at installing, upgrading and operating OpenStack
clouds.

The ceph-ansible project is hosted on GitHub, and manages development using
pull requests. However, we wanted to make sure that new commits to the project
would not break TripleO deployments. Thus, we needed a way to test incoming
pull requests and check that TripleO would still work with this to-be-merged
change.

This is where Zuul comes to play. We can configure the Zuul deployment at
`https://review.rdoproject.org <https://review.rdoproject.org>`_ so it listens to new pull requests created at
GitHub, and runs CI jobs that are already defined there to make sure everything
is still working as expected with TripleO. Finally, Zuul will report the result
in the pull request itself.


Implementation
==============

These are the steps we followed to set up the integration.

Create the github.com connection in Software Factory
----------------------------------------------------

From an already setup Software Factory installation, you will need to follow
the steps from `this guide <https://softwarefactory-project.io/docs/operator/zuul_operator.html?highlight=github_connections#create-a-github-app>`_ to
configure a GitHub connection named *github.com*. This connection will allow
Zuul to listen to events from GitHub-hosted repositories.

Create the Zuul configuration for the GitHub project
----------------------------------------------------

The second step is to add the ceph-ansible repository to the list of repos
handled by Zuul. We did this by adding the following lines to our *zuul/rdo.yaml*
file from the `review.rdoproject.org config repo <https://github.com/rdo-infra/review.rdoproject.org-config>`_.

.. code-block:: YAML

    github.com:
      untrusted-projects:
        # Don't load any in-repo configuration from these projects
      - include: []
        projects:
        - ceph/ceph-ansible

We are using the previously created *github.com* connection, and including
ceph/ceph-ansible in the Zuul configuration.

Note that, while Zuul could import extra configuration from the project (like
additional Zuul pipelines and jobs), we are going to define the configuration
in the global RDO Zuul configuration.

Install the Software Factory GitHub application on the ceph-ansible repo
------------------------------------------------------------------------

This step has to be applied on the GitHub repo configuration, to provide Zuul
with credentials to interact with the repository. To do so, we followed the steps
from `the Software Factory documentation <https://softwarefactory-project.io/docs/user/zuul_user.html#install-a-github-app>`_.

Configure a Zuul pipeline and a base no-op job
----------------------------------------------

With the previous configuration in place, we are ready to start receiving
information from GitHub pull requests and react to them. For simplicity, we
created a unique `Zuul pipeline <https://zuul-ci.org/docs/zuul/admin/quick-start.html?highlight=pipeline#configure-zuul-pipelines>`_
to handle GitHub-related jobs. We created the following configuration at
*zuul.d/github.yaml*:

.. code-block:: YAML

    ---
    - pipeline:
        name: github-check
        description: |
          Newly uploaded patchsets on GitHub enter this pipeline to receive an
          initial +/-1 Verified vote.
        success-message: Build succeeded (check pipeline).
        failure-message: Build failed (check pipeline).
        manager: independent
        require:
          rdoproject.org:
            open: True
            current-patchset: True
        trigger:
          github.com:
    # NOTE(jpena): while the pipeline and jobs are being developed, we only trigger jobs via a keyword
    #        - event: pull_request
    #          action:
    #            - opened
    #            - changed
    #            - reopened
            - event: pull_request
              action: comment
              comment: (?i)^\s*(recheck|check-rdo)\s*$
        start:
          github.com:
            status: 'pending'
            status-url: "https://review.rdoproject.org/zuul/status"
            comment: false
        success:
          github.com:
            status: 'success'
          sqlreporter:
        failure:
          github.com:
            status: 'failure'
          sqlreporter:

We configured the pipeline to react to new pull requests on the *github.com*
connection and provide a 'success' or 'failure' message depending on the job
outcome. During the testing phase, we do not want Zuul to send messages to
every pull request with (potentially) meaningless information, so we configured
the pipeline to only trigger jobs when a special keyword was added as a comment.
In this case, it was either *recheck* or *check-rdo*.

Additionally, we configured a basic, no-op job to test that our configuration
was correct. We did so by adding the following to the *zuul.d/projects.yaml*
file:

.. code-block:: YAML

    - project:
        name: ceph/ceph-ansible
        github-check:
          jobs:
            - noop

We are using the previously defined *github-check* pipeline, and assigning the
special *noop* job.

Create jobs, manage branch differences between GitHub and Software Factory
--------------------------------------------------------------------------

Once the basic integration was tested, we moved on to create some more real
jobs. We found a potential issue related to the different branches used by the
ceph-ansible project and TripleO.

* The ceph-ansible project has stable-* branches for each release, such as
  *stable-3.2*, *stable-3.1*, etc.
* TripleO, like most OpenStack project, had stable branches using code names,
  such as *stable/rocky* or *stable/queens*.

In addition to this, each ceph-ansible branch needs to be tested against
different TripleO branches, so we need to tell Zuul about the branch mapping
in each case. By doing so, we can ensure that each ceph-ansible commit is
tested against the relevant TripleO branches.

We did this as a two-step process. The first step required additions to the
`rdo-jobs <https://github.com/rdo-infra/rdo-jobs>`_ repository, which is a
repository containing the Zuul jobs used in our review.rdoproject.org instance.
We added the following to the *zuul.d/ceph-ansible.yaml* file:

.. code-block:: YAML

    - job:
        name: tripleo-ceph-integration-master
        parent: tripleo-ceph-integration
        # branches makes this job run only for master PR
        branches: master
        required-projects:
          # without options, the branch of the PR is used for the required-projects
          - name: git.openstack.org/openstack/tripleo-heat-templates
          - name: github.com/ceph/ceph-ansible

    - job:
        name: tripleo-ceph-integration-rocky
        parent: tripleo-ceph-integration
        # this job run only for stable-3.2 PR
        branches: stable-3.2
        required-projects:
          - name: git.openstack.org/openstack/tripleo-heat-templates
            # using override-checkout, we can map ceph-ansible branch to rdo branch
            override-checkout: stable/rocky
          - name: github.com/ceph/ceph-ansible

     ...

The key elements here are in the *tripleo-ceph-integration-rocky* definition:

* We specify *branches: stable-3.2*, so this job is only executed when we are
  testing a change to the stable-3.2 branch of the ceph-ansible repository.
* For the tripleo-heat-templates repository, we use
  *override-checkout: stable/rocky*. This makes Zuul checkout the stable/rocky
  branch of the project to use it when testing the change.

Effectively, this allows us to map branches from GitHub and OpenStack-hosted
repositories, to ensure the required coverage.

The second step was to use these jobs in the review.rdoproject config
repository. We changed the definition in *zuul.d/projects.yaml* to look like
the following:

.. code-block:: YAML

    - project:
        name: ceph/ceph-ansible
        templates:
          - system-required
        github-check:
          jobs:
            - tripleo-ceph-integration-master
            - tripleo-ceph-integration-rocky
            - tripleo-ceph-integration-queens

Once the change was merged, we can see the integration in action in some test
pull requests, `like this one <https://github.com/ceph/ceph-ansible/pull/3398>`_.


Additional thoughts and next steps
==================================

With the basic integration in place and working for different branches, we can
now move to the next step, and integrate a complete TripleO-based job. This
will allow us to fulfill our initial goal of gating commits to the ceph-ansible
project using TripleO jobs. We can see the start of this work on `this review <https://review.rdoproject.org/r/18734>`_.

By using the Zuul integration, we can take advantage of some of its advanced
features, like testing cross-project dependencies using the
`Depends-On <https://zuul-ci.org/docs/zuul/user/gating.html?highlight=depends#cross-project-dependencies>`_ keyword,
or using Zuul not only to check jobs, but also as a gatekeeper to merge
commits all CI jobs are successful.

Finally, during the test phase the Zuul jobs are only triggered when a specially
crafted message is added to the GitHub PR as a comment. Once jobs are stable,
we will be able to remove this requirement, and trigger jobs for every commit.
