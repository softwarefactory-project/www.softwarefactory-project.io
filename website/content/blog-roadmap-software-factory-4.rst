Software Factory 4 Roadmap
##########################

:date: 2021-03-12
:category: blog
:authors: nhicher

Hello,

Here is the roadmap for Software Factory's next major release. The 4.x release
aims to decouple the base operating system from SF services, so that Software
Factory can be deployed on RPM based flavors of Linux and containerized all SF
services.

The high level steps are:

* 4.0: modify sf-config to deploy services as containers instead of packages

  * build custom container images for services that are not available (e.g managesf) and use upstream containers for Zuul, Elasticsearch, Gerrit.

  * replace `yum install / systemctl start` by `podman run service` for all services.

  * use --volume option to transparently run the container with host files (e.g. /etc/zuul, /var/lib/zuul, /var/log/zuul).

  * replace Cauth with Keycloak for SSO and user management.

  * replace RepoXplorer with Monocle.


* 4.1: improve sf-config tasks to be closer to kubernetes.

  * change the setup workflow to run secrets creation on the install-server.

  * remove the need to have sf-config installed on each host.

  * services deployment should be consistent:

    * copy the configuration and secret.

    * create the systemd unit.

    * start the service.


* 4.2: implement sf-config as kubernetes operators.

  * update the extra glue such as config-update and cron task as kubernetes resources.

We are looking forward to this significant tech change, which should simplify
maintaining, developing and deploying Software Factory. Let us know what you
think!
