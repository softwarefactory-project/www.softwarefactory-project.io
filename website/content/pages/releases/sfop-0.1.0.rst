Software Factory Operator 0.1.0
###############################

:date: 2024-02-20 00:00
:modified: 2024-02-20 00:00
:authors: SF
:status: hidden
:url: releases/sfop-0.1.0/
:save_as: releases/sfop-0.1.0/index.html

Prelude
-------

We are excited to announce the first public release of the Software Factory Operator!

This operator is a cloud-native implementation of the Software Factory, designed to simplify deployment and maintenance as a Kubernetes workload.

With this release, we're sharing the progress we've made towards this goal. Software Factory 3.8 will continue to be supported until the official release of Software Factory Operator 1.0.0.

Doc
---

Here_ is the documentation of the 0.1.0 release.

.. _Here: https://softwarefactory-project.github.io/sf-operator/

Release Notes (2024-02-20)
--------------------------

Containers images
~~~~~~~~~~~~~~~~~

Here is the list of services versions provided as container images.

- fluentbit - "2.1.10-debug"
- gerrit - "3.6.4"
- git-daemon (git server) = "2.39.3"
- httpd = "1-284.1696531168"
- mariadb = "10.5.16"
- node-exporter = "v1.6.1"
- nodepool = "9.1.0"
- purgelogs = "0.2.3"
- sf-op-busybox = "1.5"
- sshd = "0.1"
- statsd-exporter = "v0.24.0"
- zookeeper - "3.8.3"
- zuul-client = "f96ddd00fc69d8a4d51eb207ef322b99983d1fe8"
- zuul = "9.5.0"

sf-operator-0.1.0
~~~~~~~~~~~~~~~~~

Here are changes in the sf-operator repository.

- Initial release of Software Factory Operator

