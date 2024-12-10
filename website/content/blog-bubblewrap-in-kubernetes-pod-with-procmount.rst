Secure Bubblewrap inside Kubernetes with ProcMount
##################################################

:date: 2024-12-09
:category: blog
:authors: tristanC

.. raw:: html

   <style type="text/css">

     .literal {
       border-radius: 6px;
       padding: 1px 1px;
       background-color: rgba(27,31,35,.05);
     }

   </style>

This post explores how to create nested containers securely inside
Kubernetes. In the previous post titled `Recursive namespaces to run
containers inside a container`_ I showed how to create nested containers
using a rootless container runtimes like Podman. In this post, I'll
demonstrate how to run the same workload with `Kubernetes`_.

In two parts, I will present:

-  How to run Kubernetes from source.
-  The ProcMountType feature to work around the original issue.

Context and problem statement
=============================

The context of this post is to deploy a service named zuul-executor for
running CI builds securely inside Kubernetes, without requiring a
privileged security context.

The problem is that this service performs build isolation locally using
`Bubblewrap`_, which is similar to running a container inside a
container.

Run kubernetes locally
======================

In this section, let's set up Kubernetes locally. On a fresh Fedora 41
system, install the following requirements:

.. code-block:: ShellSession

   $ sudo dnf install -y etcd crio crictl kubectl containernetworking-plugins
   $ sudo systemctl start crio

Then, start Kubernetes using the *local-up-cluster* script as follows:

.. code-block:: ShellSession

   $ mkdir -p ~/src/github.com/kubernetes; cd ~/src/github.com/kubernetes
   $ git clone https://github.com/kubernetes/kubernetes/
   $ cd kubernetes
   $ sudo env CGROUP_DRIVER=systemd CONTAINER_RUNTIME=remote CONTAINER_RUNTIME_ENDPOINT='unix:///var/run/crio/crio.sock' \
       ./hack/local-up-cluster.sh
   ...
   Local Kubernetes cluster is running. Press Ctrl-C to shut it down.

… using the following test resource:

.. code-block:: yaml

   apiVersion: v1
   kind: Pod
   metadata:
     name: test-bwrap
   spec:
     containers:
       - name: test
         image: quay.io/zuul-ci/zuul-executor
         command: ["/bin/sleep", "infinity"]
         securityContext:
           capabilities:
             add: ["SETFCAP"]

..

   As seen previously, we need *CAP_SETFCAP* to create the user
   namespace, otherwise bwrap fails early with the following error:

   ::

      bwrap: setting up uid map: Operation not permitted

Apply the test resource with the following commands:

.. code-block:: ShellSession

   $ export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig
   $ kubectl apply -f test-bwrap.yaml
   $ kubectl exec test-bwrap -- bwrap --ro-bind /lib /lib --ro-bind /usr /usr --symlink /usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session ps afx
   bwrap: Can't mount proc on /newroot/proc: Operation not permitted

This produces the same error we encountered in the `previous post`_: the
/proc filesystem is tainted in the pod, preventing Bubblewrap from being
able to create a new procfs for the new PID namespace.

The next section introduces the *ProcMountType* feature to work around
this issue.

The ProcMountType feature
=========================

The *ProcMountType* feature can be enabled by adding the following
environment variable to the *local-up-cluster*:
``FEATURE_GATES='UserNamespacesSupport=true,ProcMountType=true'``. To
make use of the new feature, we also need to activate
*UserNamespacesSupport*, as explained in the following `documentation`_.

With these features, we can update the resource like that:

.. code-block:: yaml

   apiVersion: v1
   kind: Pod
   metadata:
     name: test-bwrap
   spec:
     hostUsers: false
     containers:
       - name: test
         image: quay.io/zuul-ci/zuul-executor
         command: ["/bin/sleep", "infinity"]
         securityContext:
           procMount: Unmasked
           capabilities:
             add: ["SETFCAP"]

… using the following commands:

::

   $ sudo crictl rm -af; kubectl delete -f ./test-bwrap.yaml && kubectl apply -f ./test-bwrap.yaml
   pod/test-bwrap created
   $ kubectl exec test-bwrap -- bwrap --ro-bind /lib /lib --ro-bind /usr /usr --symlink /usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session ps afx
   bwrap: Can't mount proc on /newroot/proc: Permission denied

This time we get a new permission denied, which is caused by SELinux.
Using *audit2allow*, we can see that the following policy needs to be
installed:

::

   module nestedcontainers 1.0;

   require {
       type proc_t;
       type devpts_t;
       type container_t;
       class filesystem mount;
   }

   #============= container_t ==============
   allow container_t devpts_t:filesystem mount;
   allow container_t proc_t:filesystem mount;

… which lets us run Bubblewrap inside an unprivileged pod:

.. code-block:: ShellSession

   $ sudo semodule -i nestedcontainers.pp
   $ kubectl exec test-bwrap -- bwrap --ro-bind /lib /lib --ro-bind /usr /usr --symlink /usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session ps afx
       PID TTY      STAT   TIME COMMAND
         1 ?        Ss     0:00 bwrap --ro-bind /lib /lib --ro-bind /usr /usr --symlink /usr/lib64 /lib64 --proc /proc --dev /dev --tmpfs /tmp --unshare-all --new-session --cap-add all --uid 0 ps afx
         2 ?        R      0:00 ps afx

Notice how the ``sleep infinity`` process is not visible in the ps
output, confirming that we are indeed running in a nested container.

Conclusion
==========

This post demonstrates that we can run a container inside a container
with Kubernetes thanks to the following settings:

-  The SETFCAP to create the user namespace,
-  The ProcMountType and UserNamespacesSupport to unmask the /proc
   filesystem, and
-  A SELinux policy to enable mounting filesystems inside the new
   namespace.

.. _Recursive namespaces to run containers inside a container: https://www.softwarefactory-project.io/recursive-namespaces-to-run-containers-inside-a-container.html
.. _Kubernetes: https://kubernetes.io/
.. _Bubblewrap: https://github.com/containers/bubblewrap
.. _previous post: https://www.softwarefactory-project.io/recursive-namespaces-to-run-containers-inside-a-container.html
.. _documentation: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#proc-access
