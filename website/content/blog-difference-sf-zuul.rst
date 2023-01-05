What is the difference between Software Factory and Zuul?
#########################################################

:date: 2018-06-20
:category: blog
:authors: The Software Factory Team

Here is a detailed answer to this frequently asked question.

SF Integrates Zuul
------------------

SF is a superset of Zuul, which is similar to the openstack-infra architecture.
It provides a complete development forge including:

* Repository and code review (gerrit and cgit),
* A log server (httpd, os_loganalyze and ara),
* Collaborative tools (etherpad, lodgeit and mumble),
* Issue tracking (storyboard),
* Artifact analysis (logstash and logreduce),
* Repository analysis (repoXplorer, code-search), and
* System metrics (grafana, influxdb, telegraf, statsd).

Most components are optional and version 3.1 includes a zuul-minimal
architecture to only deploy Zuul.


SF Distributes Zuul
-------------------

We can say that SF is for Zuul what Openshift is for Kubernetes:

- It is a repository of packages to deploy Zuul on EL7. See this previous
  article: `Using system packages instead of pip <{filename}/blog-using-rpm-vs-pip.rst>`_.
- It comes with a "cluster up" command called sfconfig that deploys the services.
- It integrates the service with working default settings so that it is usable out of the box.


SF Contributes to Zuul
----------------------

Over the years we developed new features in Zuul to improve the user experience.
We are dedicated to working with upstream to integrate them in the Zuul source
code directly. Here is a highlight list:

- `GerritWatcher: add poll_timeout <https://review.openstack.org/274445>`_ and
  `Read all Gerrit events from poll interruption <https://review.openstack.org/466453>`_.
  These were two tricky bugs because they were hard to reproduce since they
  mostly happen when the Gerrit service is not busy.

- As SF moved away from Jenkins, we needed to provide a seamless user experience
  and we have heavily used the SQL reporter. In the process we found and fixed
  numerous issues, for example `sql-reporter: add support for Ref change <https://review.openstack.org/466457>`_
  and `merger/executor: configure source connections only <https://review.openstack.org/466506>`_

- To simplify Zuul's automatic configuration, SF relies on directory based configuration
  instead of a single flat file. The initial `implementation <https://review.openstack.org/152290>`_
  in ZuulV2 was not accepted. Eventually the zuul.d support was contributed to ZuulV3
  `Add support for zuul.d configuration split <https://review.openstack.org/473764>`_.

- Tenant restriction to mitigate trivial abuse:
  `Add max-nodes-per-job tenant setting <https://review.openstack.org/489481>`_ and
  `Add max-job-timeout tenant setting <https://review.openstack.org/502332>`_

- One important feature without Jenkins was a dashboard of the jobs list and previous builds.
  We drove the zuul-web effort in order to implement those features in Zuul:
  `web: add /{tenant}/jobs route <https://review.openstack.org/503270>`_ and
  `web: add /{tenant}/builds route <https://review.openstack.org/466561>`_

- `Git driver <https://review.openstack.org/525614>`_ to support simple re-use of
  the zuul-jobs collections.

- `Do not call merger:cat when all config items are excluded <https://review.openstack.org/535509>`_
  to improve startup time.

- Thanks to sf-ci, a global POST_FAILURE was prevented with
  `Revert "Don't store references to secret objects from jobs" <https://review.openstack.org/553147>`_

- Dynamic tenant configuration
  `Tenant config can be read from an external script <https://review.openstack.org/535878>`_.

- `mqtt: add basic reporter <https://review.openstack.org/535543>`_ to implement
  external log processing jobs.

- `Fix new depends-on format matching for prefixed gerrit ui <https://review.openstack.org/570006>`_

- `Make Zuul able to start with a broken config <https://review.openstack.org/535511>`_,
  this contribution prevents Zuul from breaking if a tenant merges a bad commit.

- Nodepool `driver interface <https://review.openstack.org/#/q/topic:nodepool-drivers>`_
  to initialy implement static node supports.


Future Contributions
--------------------

Here is the list of features we picked in the Software Factory version of Zuul
and Nodepool that are still under review upstream.
We are confident these features will eventually land upstream, but they might
evolve by then. They should therefore be considered a "tech preview",
although we will do our best to integrate these in the least disruptive way
possible.

- `dashboard: add /{tenant}/projects.html web page <https://review.openstack.org/537870>`_
  to list the project configured in zuul see this `projects page <https://softwarefactory-project.io/zuul/t/local/projects.html>`_.
  Clicking on a project shows a page with the configured jobs as well as d3js graph rendering of the pipeline.

- `dashboard: add /{tenant}/job.html page to display job details <https://review.openstack.org/535545>`_
  to show the job details see this `job page <https://softwarefactory-project.io/zuul/t/local/job.html?job_name=sf-rpm-build>`_.
  There is another d3js graph rendering of the jobs' relationships.

- `dashboard: add /{tenant}/labels.html web page <https://review.openstack.org/553979>`_ and
  `dashboard: add /{tenant}/nodes.html web page <https://review.openstack.org/553999>`_ to
  show the nodepool information.

- `topic: zk-retry <https://review.openstack.org/#/q/topic:zookeeper-retry>`_ to improve
  system operation when zookeeper connection is restarted.

- `config: add statsd-server config parameter <https://review.openstack.org/535560>`_

- `Implement a Runc driver <https://review.openstack.org/535556>`_ to enable thin
  container environments.

- `Implement a Kubernetes driver <https://review.openstack.org/535557>`_
  to spawn test instances in a k8s namespace.

- `Implement an OpenShift resource provider <https://review.openstack.org/#/q/topic:openshift-zuul-build-resource>`_
  to use OpenShift as a resource provider.
