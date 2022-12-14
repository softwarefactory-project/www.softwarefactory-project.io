Checking SF Operator with Kubernetes
####################################

:date: 2022-12-22
:category: blog
:authors: dpawlik

.. _early-stage-:

Early stage of SF Operator
==========================

In the beginning, the `sf-operator` were deployed on `Kind <https://kind.sigs.k8s.io/>`__ tool,
because it was fast to deploy, easy to enable features like `extraPortMapping`,
configure local storage. So it was a perfect tool to run in CI and only for CI.
After a while we realized that Kind won't be used in production and every
simplification in use will need to be applied on production environment like
Kubernetes or OpenShift.

.. _k8s-deployment-:

The Kubernetes deployment
=========================

The Kubernetes deployment compared to the Kind tool is more time consuming,
but on the end, the CI is checking the operator without any facilities.
Basic Kubernetes deployment is done by using `extra/kubernetes` role from
`sf-infra <https://softwarefactory-project.io/r/plugins/gitiles/software-factory/sf-infra/+/refs/heads/master/roles/extra/kubernetes/>`__ project.
The role uses `cri-o <https://cri-o.io/>`__ as a container runtime, `calico <https://www.tigera.io/project-calico/>`__ as networking driver,
`ingress <https://github.com/kubernetes/ingress-nginx/>`__ with localhost port mapping (port 80, 443) and
`local-path-provisioner <https://github.com/rancher/local-path-provisioner>`__.

Here is a simple playbook to deploy Kubernetes:

.. code-block:: yaml

   - name: Deploy Kubernetes
     hosts: kubernetes.dev
     roles:
       - extra/kubernetes

.. _port-mapping-:

Why ingress port mapping is bounded to host?
--------------------------------------------

We have been using host-bound ingress port mapping with Kind, and we would
like to keep doing so far for CI check, because it is simpler and takes less time.
That solution might be helpful for development purposes, that it does not
require to attach more resources from your Cloud Provider to the VM or baremetal.
With that setup, on one Kubernetes cluster we are able to deploy many
`sf-operator` deployments and communicate with the resources via host ip address,
but with a different hostname.
For example, in the resource definition of `sf-operator`, there is a `fqdn` variable:

.. code-block:: yaml

   # cat config/samples/sf_v1_softwarefactory.yaml
   apiVersion: sf.softwarefactory-project.io/v1
   kind: SoftwareFactory
   metadata:
     name: my-sf
   spec:
     fqdn: "sftests.com"
   ...

And here is how I modified my resource definition to deploy a test instance:

.. code-block:: yaml

   # cat config/samples/sf_v1_softwarefactory.yaml
   apiVersion: sf.softwarefactory-project.io/v1
   kind: SoftwareFactory
   metadata:
     name: my-sf
   spec:
     fqdn: "dpawlik.sftests.com"
   ...

By changing the `fqdn` variable to something different and re-deploy `sf-operator`
in another namespace, you should be able to perform a query:

.. code-block:: shell

   KIND_ID="123.123.123.123"
   curl "http://${KIND_IP}/" -H "HOST: etherpad.dpawlik.sftests.com"

   # or alternative way
   echo "${KIND_IP} etherpad.dpawlik.sftests.com" | sudo tee -a /ets/hosts
   echo "${KIND_IP} etherpad.sftests.com" | sudo tee -a /ets/hosts

   # make query
   curl -SL etherpad.dpawlik.sftests.com
   curl -SL etherpad.sftests.com

With `hostNetwork` and added `hostPort` for the `ingress-nginx-controller`
deployment resource, you would be able to reach the resources outside the
VM/Baremetal without deploying HAProxy, Cloud Provider resources like
IP Load Balancer or use alternative ingress configuration. [ `samples <https://kubernetes.github.io/ingress-nginx/deploy/baremetal/>`__ ]

What is worth to mention, the host port binding solution is temporary and
it is used mostly for development purpose. In the future, our team will consider
alternative configuration of ingress and local-storage-provisioner to be
more compatible with the Kubernetes/OpenShift deployment, where
the user is not an administrator.

.. _local-path-provisioner-:

The local-path-provisioner
--------------------------

Local Path Provisioner provides a way for the Kubernetes users to utilize
the local storage in each node. Based on the user configuration,
the Local Path Provisioner will create either hostPath or local based
persistent volume on the node automatically. [ `source <https://github.com/rancher/local-path-provisioner#overview>`__ ].

For the CI deployment, we create a local persistent volume, on which the service's
data is stored. However we are likely to discard this approach in future
production deployments, because the storage content needs to be available
on all nodes. It is possible to create an NFS storage, or attach the same volume
on all of the nodes, but if you are not an administrator, that solution
would be problematic.
