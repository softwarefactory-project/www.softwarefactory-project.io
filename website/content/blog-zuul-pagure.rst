An update regarding the Pagure driver for Zuul
##############################################

:date: 2018-12-18
:category: blog
:authors: Fabien Boucher

Based on the strong opinion that Zuul brings lots of advanced features for
Continuous integration and deserves to usable by more projects, I decided to
start the implementation of a Pagure driver for Zuul.

Zuul
----

Zuul is powerful gating system that help project maintainers to never break
developement branches. Thanks to features, such as speculative merging and
multi-repositories support, Zuul leverages CI at scale and provides out the box
support for Ansible (Zuul jobs are Ansible playbooks). Currently Zuul handles
Gerrit and Github as input sources. To learn more about Zuul you can access
`the Zuul website <https://zuul-ci.org/>`_ and
`the Zuul Hands-on blog post series <https://www.softwarefactory-project.io/zuul-hands-on-part-1-what-is-zuul.html>`_.

Pagure
------

Pagure is a git-centered forge, python based using pygit2, mainly but not only
used by the Fedora project. The pagure API provides most of the features needed
by Zuul to gate Pull-Requests. You can see Pagure in action `here <https://pagure.io/browse/projects/>`_
and learn more about it on the `its project's page <https://pagure.io/pagure>`_.

Pagure is quite similar to Github as it handles Pull-Requests where a PR is a branch
composed of one or more commits. A PR can be commented, reviewed, updated,
CI flagged, and merged via the API. CI results for a PR can are reported via the
flag mechanism (success/failure/pending). Code review is done via comments containing
a :thumbsup: or :thumbsdown: emoji. Pagure computes a score based on those emoji
and allow or not the merge of a PR if the *minimal score to merge* is set in
repository settings. Pagure sends repository events via webhooks and provides
repository API tokens to perform authenticated calls like merging a PR or adding
a CI flag.

The Zuul Pagure driver
----------------------

The opened review on Gerrit: https://review.openstack.org/#/c/604404/

The driver makes use of the web hooks to receive repository events such as
*Pull Request Openned* or *Pull Request commented*. Events are received via Zuul
Web and sent to the Zuul scheduler. The driver is able to read Pull-Requests
status to get the Review score via the count of :thumbsup:/:thumbsdown:
emoji, the CI status (flags) and the merge state. It is also ables to set CI status
and Pull-Request comments.

The driver provides Triggers and Requires filters attributes that can be used
to define a Zuul pipeline. Below is an example of a Zuul pipeline for a Pagure
source called *pagure.sftests.com*:

.. code-block:: yaml

 - pipeline:
     name: check
     manager: independent
     require:
      pagure.sftests.com:
         merged: False
     trigger:
       pagure.sftests.com:
         - event: pg_pull_request
           action: comment
           comment: (?i)^\s*recheck\s*$
         - event: pg_pull_request
           action:
             - opened
             - changed
     start:
       pagure.sftests.com:
         status: 'pending'
         comment: false
       sqlreporter:
     success:
       pagure.sftests.com:
         status: 'success'
       sqlreporter:
     failure:
       pagure.sftests.com:
         status: 'failure'
       sqlreporter:

 - pipeline:
     name: gate
     manager: dependent
     precedence: high
     require:
       pagure.sftests.com:
         score: 1
         merged: False
         status: success
       sqlreporter:
     trigger:
       pagure.sftests.com:
         - event: pg_pull_request
           action: status
           status: success
         - event: pg_pull_request_review
           action: thumbsup
     start:
       pagure.sftests.com:
         status: 'pending'
         comment: false
       sqlreporter:
     success:
       pagure.sftests.com:
         status: 'success'
         merge: true
         comment: true
       sqlreporter:
     failure:
       pagure.sftests.com:
         status: 'failure'
         comment: true
       sqlreporter:

 - pipeline:
     name: post
     post-review: true
     manager: independent
     precedence: low
     trigger:
       pagure.sftests.com:
         - event: pg_push
           ref: ^refs/heads/.*$
     success:
       sqlreporter:

Currently three type of events can be used as trigger in pipelines:

  - pg_pull_request: when a Pull-Request change
  - pg_pull_request_review: when a comment is added to a Pull-Request
  - pg_push: when a git branch is updated

The following requirements are supported:

  - merged: the Pull-Request merged status
  - status: the CI flag success/failure/pending
  - score: the score based on thumbsup/thumbsdown count

First PR gated by Zuul on pagure.io
-----------------------------------

.. image:: images/zuul-pagure-1.png

Setup a Pagure repository for Zuul
----------------------------------

The API token ACLs must be at least:

  - Comment on a pull-request
  - Flag a pull-request
  - Merge a pull-request

The web hook target must be (in repository settings):

  - http://<zuul-web>/zuul/api/connection/<conn-name>/payload

The repository settings (to be checked):

  - Always merge (? better to match internal merge strategy of Zuul)
  - Minimum score to merge Pull-Request
  - Notify on Pull-Request flag
  - Pull-Requests

To define the connection in /etc/zuul/zuul.conf:

.. code-block:: ini

  [connection pagure.sftests.com]
  driver=pagure
  webhook_token=TSC6UUXHUBLM52FBXG7SJZFWAIBXH7TFK8SXXXXX
  server=pagure.sftests.com
  baseurl=https://pagure.sftests.com/pagure
  cloneurl=https://pagure.sftests.com/pagure/git
  api_token=QX29SXAW96C2CTLUNA5JKEEU65INGWTO2B5NHBDBRMF67S7PYZWCS0L1AKHXXXXX

RFE merged on Pagure to support Zuul
------------------------------------

- https://pagure.io/pagure/pull-request/3857
- https://pagure.io/pagure/pull-request/3832
- https://pagure.io/pagure/pull-request/3980
- https://pagure.io/pagure/pull-request/4024
- https://pagure.io/pagure/pull-request/4121

Current issues
--------------

Here is the list of the issues that prevent the driver to have the same
capabilities than the Gerrit and Github driver.

Blocking issues
,,,,,,,,,,,,,,,

  - API token, webhook target and hook payload signature are set by repository.
    This makes difficult to support multiple repositories like in Gerrit or Github.
    An idea could be to group projects and set those settings at project's group
    level. RFE: https://pagure.io/pagure/issue/3948

Non blocking issues
,,,,,,,,,,,,,,,,,,,

  - Pagure does not send event when git tag is added/removed
  - Pagure does not send an event when a branch is created
  - Pagure does not send an event when a branch is deleted
  - Repository API token seems limited to 60 days
  - Git-receive hook payload does not contains the list of commits part
    of the merged PR with files list details. Then need an extra merger call
    to detect if a .zuul.yaml exist at the root of the reporitory file tree.
  - Pagure does not reset the review score when a PR code is updated.
    RFE: https://pagure.io/pagure/issue/3985
  - CI status flag *updated* field unit is the second, better to have millisecond
    unit to avoid unpossible sorting to get last status if two status set at the
    same second.
  - Zuul needs to be able to search commits that set a dependency (depends-on)
    to a specific commit to reset jobs run when a dependency is changed. On
    Gerrit and Github search through commits message is possible and used by
    Zuul. Pagure does not offer this capability.

Follow up
---------

- Showcase the driver to the Pagure folks
- Implement https://pagure.io/pagure/issue/3948
- Write the driver unittests and documentation
- By Pagure 5.3, have a multi-repository (depends-on) workflow working

Any help welcome :)
