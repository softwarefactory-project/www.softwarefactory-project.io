Ingress on CodeReady Containers
###############################

:date: 2022-12-12
:category: blog
:authors: daniel

CRC - CodeReady Containers
==========================

Why we are using it?
--------------------

The CRC (Red Hat CodeReady Containers) is a solution to deploy OpenShift
cluster on your local machine in minutes.
Red Hat OpenShift provides a complete solution that includes a stable Kubernetes
engine with robust security and many integrated capabilities required to
operationalize a complete application platform. It comes in several
editions including as a fully managed public cloud service or
self-managed on infrastructure across datacenters, public clouds, and edge. [`source <https://www.redhat.com/en/technologies/cloud-computing/openshift/red-hat-openshift-kubernetes#benefits>`]

That project requires much resources, due it deploys a dedicated libvirt instance,
configure network, deploy Kubernetes inside the instance and on the end
deploys OpenShift with operators.
All new pods that would be spawned later by `sf-operator` would be running inside
that VM, that's why the minimum of our configuration to deploy CRC and `sf-operator`
took 14 GB of RAM, 6 vcpus and 60 GB of HDD.

The SF Operator project is already tested on pure Kubernetes deployment, however
we cannot assume that all of Software Factory Project users are using it.
The future Software Factory release that would be base on Kubernetes deployment
should be also tested on different platform. That's why take additional work to
create an universal operator, that would be possible to deploy on many
Kubernetes base clusters.


How to setup CRC?
-----------------

The CRC deployment is easy to deploy. The CRC community has simple `documentation <https://crc.dev/crc/>`.
Also the OpenStack community creates own repository to easy setup
the environment by fallowing `manual <https://github.com/openstack-k8s-operators/install_yamls/tree/master/devsetup#crc-automation--tool-deployment>`.

The Software Factory Project uses the crc Ansible role, which
you can find in `sf-infra <https://softwarefactory-project.io/r/plugins/gitiles/software-factory/sf-infra>` repository.

Simply playbook to deploy CRC looks like:

NOTE: That playbook requires to reboot the host to apply nested
virtualization. It is also optional procedure, but it is recommended to
apply to improve performance.

.. raw:: yaml

   - hosts: crc.dev
     vars:
       crc_debug: true
       opeshift_pull_secret: |
         < ADD YOUR PULL-SECRET.TXT HERE>
     pre_tasks:
       - name: Update packages
         become: true
         package:
           name: '*'
           state: latest
       - name: Install packages
         become: true
         yum:
           name:
             - qemu-kvm-common
           state: present
       - name: Ensure CentOS runs with selinux permissive
         become: true
         selinux:
           policy: targeted
           state: permissive
       # NOTE: Enabling nested virtualization is optional, but
       # it will improve performance.
       - name: Check if CPU vendor is Intel
         shell: |
           grep -qi intel /proc/cpuinfo
         register: _intel_vendor
       - name: Enable nested virtualization - Intel
         become: true
         lineinfile:
           path: /etc/modprobe.d/kvm.conf
           regexp: '^#options kvm_intel nested=1'
           line: 'options kvm_intel nested=1'
         when: _intel_vendor.rc == 0
         register: _nested_intel
       - name: Enable nested virtualization - AMD
         become: true
         lineinfile:
           path: /etc/modprobe.d/kvm.conf
           regexp: '^#options kvm_amd nested=1'
           line: 'options kvm_amd nested=1'
         when: _intel_vendor.rc == 1
         register: _nested_amd
       - name: Reboot host to apply nested virtualization change
         become: true
         reboot:
         when: _nested_intel.changed or _nested_amd.changed
     roles:
       - extra/crc
     ## NOTE: Below tasks are not neccesary to execute. There might be helpful
     ## on creating the VM snapshot after the deployment.
     #post_tasks:
     #  - name: Remove pull-secret file
     #    file:
     #      path: pull-secret.txt
     #      state: absent
     #  - name: Ensure cloud-init is installed
     #    become: true
     #    package:
     #      name:
     #        - cloud-init
     #        - golang
     #      state: present
     #  - name: Cleanup dnf cache
     #    become: true
     #    shell: dnf clean all
     #  - name: Create crontab entry to generate local ssh keys
     #    become: true
     #    copy:
     #      content: |
     #        @reboot root /usr/bin/ssh-keygen -A; systemctl start sshd
     #      dest: /etc/cron.d/ssh_gen
     #  - name: Set proper selinux label
     #    become: true
     #    shell: |
     #      /usr/bin/chcon system_u:object_r:system_cron_spool_t:s0 /etc/cron.d/ssh_gen

where the pull-secret.txt can be generated `here <https://cloud.redhat.com/openshift/create/local>`.

Ingress - how it's done for testing purpose
-------------------------------------------

As you might know, ingress exposes HTTP and HTTPS routes from outside the
cluster to services within the cluster. Traffic routing is controlled by
rules defined on the Ingress resource. [`source <https://kubernetes.io/docs/concepts/services-networking/ingress/#what-is-ingress>`]

At the very beginning of the creation of the `sf-operator`, tests were performed
on `Kind <https://kind.sigs.k8s.io/>` tool, which got a dedicated configuration
to enable `extraPortMapping <https://kind.sigs.k8s.io/docs/user/ingress/#setting-up-an-ingress-controller>`.

Similar solution we have applied on Kubernetes deployment for testing purpose.
Soon there will be a new post on our blog about testing `sf-operator` on
Kubernetes.

By default, the VM L0 (the VM where you are deploying CRC), creates a new
network that is also routed on that VM. In most cases, the ip address of the
crc services are binded to `192.168.130.11`.
It means, that to communicate with the services such as Openshift Web Console
or sf-operator deployed services, it requires to:

- add security group rules to your instance (if you are deploying CRC in Cloud Provider VM),
- setup HAProxy that will redirect queries to the services working in CRC network.

How to add the security group rules should be described in your Cloud Provider
documentation, so I will skip that step.

How to enable CRC Console by using HAProxy
------------------------------------------

The manual is based on blog `post <https://nerc-project.github.io/nerc-docs/other-tools/kubernetes/crc/#using-crc-web-interface>`.
How to enable:

- install required services

.. raw:: sh
   sudo dnf install -y haproxy policycoreutils-python-utils

- configure environment variables

.. raw:: sh
   export SERVER_IP=$(hostname --ip-address |cut -d\  -f3)
   export CRC_IP=$(crc ip)

- create HAProxy configuration

.. raw:: sh
   cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
   global

   defaults
   log global
   mode http
   timeout connect 0
   timeout client 0
   timeout server 0

   frontend apps
   bind ${SERVER_IP}:80
   bind ${SERVER_IP}:443
   option tcplog
   mode tcp
   default_backend apps

   backend apps
   mode tcp
   balance roundrobin
   option ssl-hello-chk
   server webserver1 ${CRC_IP}:443 check

   frontend api
   bind ${SERVER_IP}:6443
   option tcplog
   mode tcp
   default_backend api

   backend api
   mode tcp
   balance roundrobin
   option ssl-hello-chk
   server webserver1 ${CRC_IP}:6443 check
   EOF

- add SELinux policy (if you did not set SELinux to permissive)

.. raw:: sh
   sudo semanage port -a -t http_port_t -p tcp 6443

- start the service

.. raw:: sh
   sudo systemctl start haproxy
   sudo systemctl enable haproxy

- optionally, generate the /etc/hosts entries (execute that on crc host, but add into your local VM)

.. raw:: sh
   echo "$(ip route get 1.2.3.4 | awk '{print $7}' | tr -d '\n') console-openshift-console.apps-crc.testing api.crc.testing canary-openshift-ingress-canary.apps-crc.testing default-route-openshift-image-registry.apps-crc.testing downloads-openshift-console.apps-crc.testing oauth-openshift.apps-crc.testing apps-crc.testing" | sudo tee -a /etc/hosts

Above steps are automatically done by Ansible due it has been included in
`extra/crc` role in `sf-infra` project.

After applying that, the OpenShift WebUI console should be available on
`https://console-openshift-console.apps-crc.testing/`.
