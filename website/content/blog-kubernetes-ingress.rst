Checking SF Operator with Kubernetes
####################################

:date: 2022-12-14
:category: blog
:authors: dpawlik


Early stage of SF Opeartor
==========================

On the beginning, the `sf-operator` were deployed on `Kind <https://kind.sigs.k8s.io/>` tool,
because it was fast to deploy, easy to enable features like `extraPortMapping`,
configure local storage. So it was a perfect tool to run in CI and only for CI.
After a while we realize that the Kind will be not used on the production and
all simplification in use needs to be applied on production environment like
Kubernetes or OpenShift.

The Kubernetes deployment
=========================

The Kubernetes deployment comparing to the Kind tool is more time consuming,
but on the end, the CI is checking the operator without any amenities.
Basic Kubernetes deployment is dony by using `extra/kubernetes` role from
`sf-infra <https://softwarefactory-project.io/r/plugins/gitiles/software-factory/sf-infra/+/refs/heads/master/roles/extra/kubernetes/>` project.
The role uses `cri-o <https://cri-o.io/>` as a container runtime, `calico <https://www.tigera.io/project-calico/>` as networking driver,
`ingress <https://github.com/kubernetes/ingress-nginx/>` with localhost port mapping (port 80, 443) and
`local-path-provisioner <https://github.com/rancher/local-path-provisioner>`.

Simply playbook to deploy Kubernetes:

.. raw:: yaml
   - name: Deploy Kubernetes
     hosts: kubernetes.dev
     roles:
       - extra/kubernetes

Why ingress port mapping is binded to host?
-------------------------------------------

So far, we would like to keep same habbits as we have done for Kind.
That solution might be helpful for development purposes, that it does not
require to attach more resources from your Cloud Provider to the VM or baremetal.
With that setup, on one Kubernetes cluster we are able to deploy many
`sf-operator` deployments and communicate with the resources via host ip address,
but with a different hostname.
For example, in the `sf-operator` in resource definition, there is a `fqdn` variable:

.. raw:: sh
   # cat config/samples/sf_v1_softwarefactory.yaml
   apiVersion: sf.softwarefactory-project.io/v1
   kind: SoftwareFactory
   metadata:
     name: my-sf
   spec:
     fqdn: "sftests.com"
   ...

And the second resource looks like:

.. raw:: sh
   # cat config/samples/sf_v1_softwarefactory.yaml
   apiVersion: sf.softwarefactory-project.io/v1
   kind: SoftwareFactory
   metadata:
     name: my-sf
   spec:
     fqdn: "dpawlik.sftests.com"
   ...

By changing the `fqdn` variable to some different and re-deploy `sf-operator`
in another namespace, you should be able to perform a query:

.. raw:: sh
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
IP Load Balancer or use alternative ingress configuration. [`samples <https://kubernetes.github.io/ingress-nginx/deploy/baremetal/>`]

Alternative way is to setup HAProxy with basic configuration:

.. raw:: sh


   TBD - need more tests





   sudo dnf install -y haproxy policycoreutils-python-utils

   # Check the ingress services
   kubectl -n ingress-nginx get svc

   # it should be something like:
   NAME                                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
   ingress-nginx-controller             NodePort    10.96.90.217   <none>        80:32265/TCP,443:30953/TCP   9m37s
   ingress-nginx-controller-admission   ClusterIP   10.96.91.46    <none>        443/TCP                      9m37s

   # Where the port 80 is redirected to 32265 and port 443 to 30953

   INGRESS_GW="10.96.90.217"
   PORT_HTTP=32265
   PORT_HTTPS=30953
   sudo tee /etc/haproxy/haproxy.cfg &>/dev/null <<EOF
   global
       log /dev/log local0

   defaults
       balance roundrobin
       log global
       maxconn 100
       mode tcp
       timeout connect 5s
       timeout client 500s
       timeout server 500s

   listen apps
       bind 0.0.0.0:80
       server k8s $INGRESS_GW:$PORT_HTTP check

   listen apps_ssl
       bind 0.0.0.0:443
       server k8s $INGRESS_GW:$PORT_HTTPS check
   EOF

   sudo systemctl restart haproxy
   sudo systemctl enable haproxy

With that solution, if you want to reach the `sf-operator` services by making
query to the Kubernetes host will work, but it requires an additional
step, which can be also a point of failure.

What is worth to mention, the host port binding solution is temporary and
it is used mostly for development purpose. In the future, our team will consider
alternative configuration of ingress and local-storage-provisioner to be
more compatible with the Kubernetes/OpenShift deployment, where
the user is not an administrator.

The local-path-provisioner
--------------------------

TBD
