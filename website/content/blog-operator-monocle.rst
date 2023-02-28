Monocle Operator - Day 1
########################

:date: 2023-03-01
:category: blog
:authors: Fabien Boucher

.. raw:: html

   <style type="text/css">

     .literal {
       border-radius: 6px;
       padding: 1px 1px;
       background-color: rgba(27,31,35,.05);
     }

   </style>

This post aims to explains how we built a k8s Operator using the
`operator sdk`_ for the `Monocle`_ project. We'll cover the following
topics:

-  What is a k8s Operator
-  How to create the project skeleton
-  Workflows related to the Monocle's operations
-  Handling Monocle' workflows with the Operator
-  How to test the Operator
-  How to deploy the operator in production

.. _what-is-a-k8s-operator-:

What is a k8s Operator ?
========================

An `Operator`_ is a software capables of handling various operations
related to another software. The Operator handles operations usually
ensured by a SRE.

Handled operations are such as (but not limited to):

-  Deployment
-  Re-configuration
-  Update
-  Scaling
-  Backup

To create an Operator a developer needs to well understand how to
operate the target software.

A multitude of Operators for various softwares are already available
especially on `Operator Hub`_.

An Operator is designed to live inside a k8s or OpenShift deployment.
The operator uses k8s' resources (Deployment, ConfigMap, ...) to handle
the target software' operations. It defines at least one CR (`Custom
Resource`_) that can be configured via a CRD (`Custom Resource
Defintion`_) and a Custom Controller by CR.

A Custom Controller watches for instances of a CR and ensures that k8s'
resources needed by the CR's instance are spawned and fully functional.
The controller runs continuously and reacts to various events ensuring
the declared state of the software is maintained. This is called
"Reconciliation".

In this blog post we introduce an Operator for the Monocle software,
based on a Custom Resource and a Custom controller. The controller is
implemented in Go to benefit from well tested and documented libraries.

.. _how-to-create-the-project-skeleton-:

How to create the project skeleton ?
====================================

The `Operator framework project`_ provides a `SDK`_ to ease the
bootstrap and maintainance of an operator.

First install the `GO operator SDK`_:

.. code-block:: bash

   curl -OL https://github.com/operator-framework/operator-sdk/releases/download/v1.26.0/operator-sdk_linux_amd64
   mkdir -p ~/.local/bin && mv operator-sdk_linux_amd64 ~/.local/bin/operator-sdk && chmod +x ~/.local/bin/operator-sdk

`Initialise your repository`_ using the ``init`` sub command:

.. code-block:: bash

   mkdir monocle-operator && cd monocle-operator
   git init .
   operator-sdk init --repo github.com/change-metrics/monocle-operator --owner "Monocle developers" --domain monocle.change-metrics.io
   git diff
   git add -A . && git commit -m"Init the operator"

Then, `add the new API`_ (a CRD) and a controller for the new Custom
Resource ``Monocle``:

.. code-block:: bash

   operator-sdk create api --group monocle --version v1alpha1 --kind Monocle --resource --controller
   git status
   git diff
   git add -A . && git commit -m"Add skeleton code for the Monocle CR"

If the Operator handles more CRs then run the previous command with the
new ``Kind``.

The SDK for a `GO operator`_ generates the project code structure
composed of:

-  A PROJECT file that describes the managed's (by the SDK) operator
-  A Makefile. It handles various tasks such as:

   -  CRD Yaml definition based on Go types, Roles definition based on
      code markers
   -  operator code lint
   -  operator start in developement mode
   -  operator image build and publish
   -  operator deployment
   -  generate OLM bundle

-  A Dockerfile used to build the operator container image
-  Go code skeleton based on the `controller-runtime library`_:

   -  main.go: The entry point that defines the controler-runtime's
      manager and start the CR's controller.
   -  controllers/<cr-name>_controller.go: The controller code skeleton,
      including the `reconcile loop`_ function.
   -  controllers/suite_test.go: A test suite skeleton
   -  api/<api-version>/<cr-name>_types.go: The Custom Resource
      Definition (the spec and the status).

-  YAML files:

   -  config/crd: the auto-generated CRD yaml file
   -  config/manager: the auto-generated YAML that define the operator's
      manage deployment, and namespace
   -  config/rbac: Auto-generated Role Based Access Control defintions

      -  service_account.yaml: The service account that the operator
         will use to act on the k8s's API.
      -  role.yaml: Defines the ``manager-role`` role which define
         authorized actions on our new controller's resources.
      -  role_binding.yaml: Binds the service account to the
         ``manager-role``.
      -  leader_election_role_(binding).yaml: Enables use of leaders
         related resources for the service account.
      -  <cr-name>-(viewer|editor)_role.yaml: Roles to allow users to
         read or edit the Custom Resource.

   -  config/sample: a ready to use YAML to deploy our new CR
   -  default/kustomization.yaml: The entrypoint of the `kustomize`_
      configuration for YAML generations.

We can see that an Operator is, at least defined, by the following
resources:

-  A `manager`_ and a set of `controllers`_
-  A set of `CRDs`_
-  A container image capable of running the ``manager``
-  A suite of YAML manifests to apply to the Kubernetes cluster to
   deploy the operator

From there we are ready to write the Monocle Operator.

Workflows related to the Monocle's operations
=============================================

An operator handles various workflows for the targeted software. Thus,
as a first step we need to identify exactly what are those workflows and
what they involve.

For our ``Day 1`` journey we'd like to handle the deployment and the
configuration of Monocle. It is important to have a minimum
understanding of the software we intent to create an operator for so
feel free to read the `Monocle's README file`_.

Deployment
----------

A minimal Monocle deployment is composed of at three services. The
upstream project provide a `Docker Compose recipe`_ that we will
replicate.

The database (ElasticSearch)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Monocle needs to get access to an ElasticSearch instance:

-  The service needs a storage for its indices.
-  We can use the upstream ElasticSearch container image.
-  We can rely on the minimal and default settings.

The Monocle API (serve the API and the WEB UI)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-  The upstream project provides a container image.
-  The service a stateless.
-  A configuration file is needed.
-  Some environment variables must be exposed (especially for the
   secrets).

The Monocle crawler
~~~~~~~~~~~~~~~~~~~

The crawler requires the same as the API.

Configuration
-------------

Here we need to determine how an Human will interact with the Monocle
Operator in order to change the Monocle configuration.

Update secrets
~~~~~~~~~~~~~~

The `secrets`_ hosts sensitive information used by the API and the
crawler processes (Code Review provider's API tokens, OpenID Token,
...). Any changes on the ``secrets`` require an API and crawler
processes restart.

.. _update-configyaml:

Update config.yaml
~~~~~~~~~~~~~~~~~~

The `config file`_ is used by the API and the crawler. Monocle is able
to detect changes in its configuration file and reload the
configuration.

The ``janitor update-idents`` command must be run in case of updating
the ``config file`` to `update identities`_.

Handling Monocle' workflows with the Operator
=============================================

How the operator starts Monocle' components
-------------------------------------------

How the operator handles Monocle' reconfigurations
--------------------------------------------------

How to test the Operator
========================

How to deploy the operator in production
========================================

To see which manifest are deployed (``kubectl apply -f``) by make deploy
run:

.. code-block:: bash

   $ ./bin/kustomize build config/default

To conclude and more reading
============================

Ideas for later:

-  Adding a MonocleCrawler Custom Resource.

The `operator pattern white paper`_.

.. _operator sdk: https://htmx.org
.. _Monocle: https://change-metrics.io
.. _Operator: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
.. _Operator Hub: https://operatorhub.io
.. _Custom Resource: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
.. _Custom Resource Defintion: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions
.. _Operator framework project: https://operatorframework.io/
.. _SDK: https://htmx.org
.. _GO operator SDK: https://sdk.operatorframework.io/docs/building-operators/golang/quickstart/
.. _Initialise your repository: https://sdk.operatorframework.io/docs/cli/operator-sdk_init/
.. _add the new API: https://sdk.operatorframework.io/docs/cli/operator-sdk_create_api/
.. _GO operator: https://sdk.operatorframework.io/docs/building-operators/golang/quickstart/
.. _controller-runtime library: https://pkg.go.dev/sigs.k8s.io/controller-runtime
.. _reconcile loop: https://pkg.go.dev/sigs.k8s.io/controller-runtime@v0.14.5/pkg/reconcile
.. _kustomize: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
.. _manager: https://pkg.go.dev/sigs.k8s.io/controller-runtime#hdr-Managers
.. _controllers: https://pkg.go.dev/sigs.k8s.io/controller-runtime#hdr-Controllers
.. _CRDs: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions
.. _Monocle's README file: https://github.com/change-metrics/monocle#readme
.. _Docker Compose recipe: https://github.com/change-metrics/monocle/blob/master/docker-compose.yml
.. _secrets: https://github.com/change-metrics/monocle#environment-variables
.. _config file: https://github.com/change-metrics/monocle#configuration-file
.. _update identities: https://github.com/change-metrics/monocle#apply-idents-configuration
.. _operator pattern white paper: https://github.com/cncf/tag-app-delivery/blob/eece8f7307f2970f46f100f51932db106db46968/operator-wg/whitepaper/Operator-WhitePaper_v1-0.md
