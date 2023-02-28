Monocle Operator - Day 1
########################

:date: 2023-03-01
:category: blog
:authors: Fabien Boucher

.. raw:: html

   <style type="text/css">
   </style>

This post aims to explains how we built a k8s Operator using the `operator sdk`_ for
the `Monocle`_ project. We'll cover the following topics:

- What is a k8s Operator
- How to create the project skeleton
- Workflows related to the Monocle's operations
- Handling Monocle' workflows with the Operator
- How to test the Operator
- How to deploy the operator in production

.. _what-is-a-k8s-operator-:

What is a k8s Operator ?
========================

An Operator is a software capables of handling various operations related to
another software. The Operator handles operations usually ensured by a SRE.

Handled operations are such as (but not limited to):

- Deployment
- Re-configuration
- Update
- Scaling
- Backup

To create an Operator a developer needs to well understand how to operate
the target software.

A multitude of Operators for various softwares are already available expecially
on `Operator Hub`_.

An Operator is designed to live inside a k8s or OpenShift deployment. The operator
uses k8s' resources (Deployment, ConfigMap, ...) to handle the target software'
operations. It defines at least one CR (Custom Resource) that can be configured via
a CRD (Custom Resource Defintion) and a Custom Controller by CR.

A Custom Controller watches for instances of a CR and ensures that k8s' resources
needed by the CR's instance are spawned and fully functional. The controller
runs continuously and reacts to various events ensuring the declared state
of the software is maintained. This is called "Reconciliation".

In this blog post we introduce an Operator for the Monocle software, based on a
Custom Resource and a Custom controller. The controller is implemented in Go to
benefit from well tested and documented libraries.

.. _how-to-create-the-project-skeleton-:

How to create the project skeleton ?
====================================

.. _workflow-related-to-the-monocle-s-operations:

Workflows related to the Monocle's operations
=============================================


.. _handling-monocle--workflow-with-the-operator:

Handling Monocle' workflows with the Operator
=============================================

How the operator starts Monocle' components
...........................................

How the operator handles Monocle' reconfigurations
..................................................

.. _how-to-test-the-operator:

How to test the Operator
========================

.. _how-to-deploy-the-operator-in-production:

How to deploy the operator in production
========================================


.. _operator SDK: https://htmx.org
.. _Monocle: https://change-metrics.io
.. _Operator Hub: https://


https://github.com/cncf/tag-app-delivery/blob/eece8f7307f2970f46f100f51932db106db46968/operator-wg/whitepaper/Operator-WhitePaper_v1-0.md
