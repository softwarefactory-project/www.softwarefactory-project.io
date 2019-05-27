Zuul Hands on - part 6 - Cross project dependencies
---------------------------------------------------

:date: 2019-10-01
:category: blog
:authors: Zoltan Caplovi, Matthieu Huin
:tags: zuul-hands-on-series

In this article, we will explain how project dependencies work in Zuul.

This article is part of the `Zuul hands-on series <{tag}zuul-hands-on-series>`_.

The examples and commands that follow are intended to be run on a Software Factory
sandbox where a **demo-repo** repository exists. You should have such an environment
after following the previous articles in this series:

- To deploy a Software Factory sandbox please read the `first article of the series <{filename}/blog-zuul-01-setup-sandbox.rst>`_.
- To create the **demo-repo** repository, please follow the sections `Clone the config repository <{filename}/blog-zuul-03-Gate-a-first-patch.rst#clone-the-config-repository>`_
  and `Define the demo-repo repository <{filename}/blog-zuul-03-Gate-a-first-patch.rst#define-the-demo-repo-repository>`_ sections.

Incidentally, most of the links reference *sftests.com* which is the default
domain of the sandbox. Make sure to adapt the links if necessary.

If you have already deployed a Software Factory sandbox and created a snapshot as
suggested, you can restore this snapshot in order to follow this article on a clean environment.
In that case make sure the virtual machine's time is correct post
restoration. If not fix it by running

.. code-block:: bash

  systemctl stop ntpd; ntpd -gq; systemctl start ntpd

The Case for Cross-Project Testing
..................................

Software tends to be less and less monolithic, and even before that trend took off
most software projects depended on third party libraries or external frameworks.
Even from an architectural standpoint, it isn't rare to see projects split into
functional subcomponents, like frontends, client libraries, or servers. And with
the advent of containerized applications and micro-services, it becomes more and
more complex to ensure that every cog in the system works well with the other.

Zuul was designed with dependency testing in mind, and can help a
development team make sure that changes to any subcomponents
won't break the whole project.

Zuul's Dependent Pipelines vs Independent Pipelines
...................................................

We've introduced the notion of pipelines in Zuul `in a previous article of the series <{filename}/blog-zuul-05-the-gate-pipeline.rst>`_.
It's time to explore the subject further and explain how pipelines can be
**Dependent** or **Independent**.

Shared workspaces
'''''''''''''''''

Zuul can be configured to incorporate branches (usually master but not necessarily)
of other projects into its workspace for a given job. This can be done with the
``required-projects`` stanza in a job definition, for example:

.. code:: yaml

  ---
  - job:
    name: sf-ci
    parent: base
    description: The sf ci tests
    post-run: playbooks/get-logs.yaml
    timeout: 10800
    required-projects:
      - software-factory/sf-ci
      - software-factory/sfinfo
    nodeset:
      nodes:
        - name: install-server
          label: cloud-centos-7

Whenever the job ``sf-ci`` is being run, Zuul will also pull the *sf-ci* and
*sfinfo* projects into the job's workspace. Of course, these projects need to
be known to Zuul through its tenants and projects configuration.

It is also possible to include other projects known to Zuul with the "`Depends-On`_"
stanza, as we will explain below. In that case, the jobs must handle the case where
such projects are present in the workspace.

Independent Pipelines
'''''''''''''''''''''

When a pipeline is **Independent**, changes that land in that pipeline are tested
independently from each other, meaning that the tests are not sharing a common
workspace during testing. This is fine when doing preliminary validation, like
in the **check** pipeline.

As an example, let's assume three projects A, B, C defined in Zuul; their **check** and **gate**
pipelines are configured to execute a job called *myjob* which requires A, B and C.

Let's also assume three patches landing in the check pipeline in the following order:

* A1 on project A
* B1 on project B
* A2 on project A

*myjob*'s respective workspaces will be:

.. image:: images/independent_pipeline_A2.png

In that case patches are tested independently and the builds can be run in parallel.

Dependent Pipelines
'''''''''''''''''''

When a pipeline is **Dependent**, it means that it can define **queues** to which
projects can be associated. All the patches of projects that belong to the same queue
are tested together, in their order of landing in the pipeline; it means that
they are included into each new workspace as patches get tested.Typically,
**gate**-type pipelines should be defined as dependent in order to catch
dependency problems before they get merged.

Let's now assume projects A, B and C belong to queue "abc" on the gate pipeline.
When patches A1, B1 and A2 land in the gate pipeline in that order, this is what
the respective workspaces for *myjob* will look like:

.. image:: images/dependent_pipeline_A2.png

A **Dependent** pipeline will catch any problem introduced by incompatibilities
brought by new patches.

Depends-On
..........

What if a patch needs an unmerged dependency to pass the check pipeline? This
can happen, for example, when an incoming patch on a client library expects an
implementation of the server API that is still being reviewed. Independent pipelines
allow cross-dependency testing as well by using the **Depends-On** keyword. By
adding a line like::

    Depends-On: path/to/patch

In the commit message or the Pull Request's description, you can make Zuul aware
that a patch must be added to the workspace. Of course, this propagates to dependent
pipelines as well.

This is a very powerful feature that allows developers to work on several components
in parallel, regardless of how fast patches get merged. With any other CI system,
a developer would have to wait until the dependency gets merged before s.he can
get feedback on his/her patch from the CI!

Zuul's Depends-On supports GitHub or Pagure Pull Requests URIs, Gerrit review
URIs or Change-IDs, or any other git source defined in Zuul's configuration.

Example
.......

Let's put together a real-life scenario to illustrate dependency testing:

Create a "sister" project to our first project demo-repo: *demo-lib*
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Define demo-lib's initial CI
''''''''''''''''''''''''''''

Declare the dependency between demo-repo and demo-lib in Zuul
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Use the dependency in demo-repo's test job
''''''''''''''''''''''''''''''''''''''''''

Create a patch on demo-repo depending on a patch on demo-lib
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
