Operators and Monitoring: making life easier for deployers
##########################################################

:date: 2023-10-10
:category: blog
:authors: Matthieu Huin

In this article, I will share my thoughts, feedback and ideas following the `work I have done
on monitoring operands`_ for the `SF Operator`_, in the hopes that other developers looking to add deep
insights and automated service tuning to their own operators may build upon my experience.

If you can't measure it, you can't size it properly
===================================================

Orchestrating applications with Kubernetes opens up a world of possibilities. Among the biggest game changers,
according to me, we have:

- Upgrade strategies that also simplify rollback should a problem arise
- Horizontal scaling and load balancing your workload, two often dreaded Ops tasks (I know I do!), become much simpler
  to handle. More often than not, it's just about changing the replica count in a manifest; your
  cluster handles the rest under the hood.

Scaling up or down, however, requires knowledge of **when** it should occur. While Kubernetes' `Horizontal Pod Autoscaling`_
can trigger scaling on CPU or memory usage automatically, application deployers with deeper knowledge of
their software may want to react on more precise events that can be measured. And that is where monitoring embedded
into an operator comes into play.

Operator developers can define their Pods to include a way to emit metrics. They can also use the operator's
controllers to configure metrics collection, so that a Prometheus instance will know automatically how to scrape these
metrics. Finally, with operations knowledge, the operator can include interesting alerts that will
trigger when the application operates outside of its expected behavior.

And when you deploy an application with such an operator, you get all that operating knowledge for free!

The Prometheus Operator
=======================

The `prometheus operator`_, unsurprisingly, is truly the cornerstone of enabling monitoring with
operators. It provides a declarative API (ie "give me a Prometheus instance!", or "monitor this pod!")
that makes it really simple to set up a monitoring environment and work with monitoring resources in
an operator's source code.

I would recommend installing the prometheus operator on any Kubernetes cluster that will run
applications. You can then spin up a Prometheus instance that will collect metrics emitted on a given namespace
and/or from resources matching specific labels.

On OpenShift, the prometheus operator can optionally be installed at deployment time,
which will result in a cluster-wide instance of Prometheus that can collect application metrics automatically.

Exposing your operands' metrics
===============================

In the development of the SF-Operator, we face three categories of operands when it comes to metrics:

- The operand's underlying application(s) emit prometheus metrics
- The operand's underlying application(s) do not emit relevant metrics, and we desire Pod-related metrics
- The operand's underlying application(s) emit statsD metrics

Let's dive into the details of each case.

The Operand emits prometheus metrics
------------------------------------

This is the case for Zuul. It is truly the simplest case since it is enough to:

- `ensure emitting the metrics is enabled in the operand's configuration`_
- `ensure the right port is declared in the relevant container spec`_

We could also add a route to enable an external Prometheus to scrape the metrics endpoint,
but since we target OpenShift we make the assumption that a Prometheus instance that is internal
to the cluster will be used.

The Operand doesn't emit relevant metrics, and we desire Pod-related metrics
----------------------------------------------------------------------------

This is the case with the Log server. Basically, this operand is just an Apache server and an SSH server taped together
on top of storage. We **could** look into `emitting Apache metrics to be scraped by Prometheus`_, but from years of
operating several large Software Factories, we know for a fact that SSH and HTTPD performances are nearly never bottlenecks
in our use cases.

What we **do want** to keep an eye on, however, is disk usage, and down the line be notified when available space
is below 10% of total capacity. When testing on MicroShift, I never actually managed
to collect kubelet metrics that are supposed to expose statistics on persistent volumes being used. This is why I
opted to expose disk usage metrics with a sidecar container running `Node Exporter`_. Slap that container onto
your Pod, and voilà! You're basically back to case 1.

You can see how it is implemented in the SF-operator as a `helper function called "MkNodeExporterSideCarContainer"`_,
and `within the Log server controller`_.

The Operand emits statsD metrics
--------------------------------

This is the case with Nodepool and Zuul. For simplicity's sake, we would like to aggregate all metrics in Prometheus.
This can be done easily with a sidecar container running `StatsD Exporter`_. All you need is a `mapping configuration file`_
that will tell the exporter how to translate statsD metrics into prometheus metrics - especially where the labels are
in the original metric's name. Once again, all you need then is to expose the exporter's service port and your metrics are
ready to be scraped.

Like for Node Exporter, we created a `helper function called "MkStatsdExporterSideCarContainer"`_ that makes it easy
to emit statsd metrics from a Pod in a Prometheus-friendly format.

Making sure the metrics will be collected
=========================================

In the last paragraph, we made sure our metrics can be scraped from our Pods. Thanks to the prometheus operator, we can
go one step further and tell *any* Prometheus instance running on the cluster how to pick these metrics up.

The prometheus operator defines the `PodMonitor`_ and the `ServiceMonitor`_ custom resources that, as their names suggest,
will define how to monitor a given pod or service. Since as I said earlier, we didn't deem necessary to create services
for each monitoring-related port, we `opted to manage PodMonitors in the SF-Operator`_. All you need is to specify the
"monitoring" ports' names to scrape on the Pod, and set a label selector (in our case, every PodMonitor related to
a SF deployment will have a label called ``sf-monitoring`` set to the name of the monitored application).

If a cluster-wide Prometheus instance exists, for example if you're using an OpenShift cluster with this feature enabled,
you can then access metrics from your SF deployment as soon as it is deployed. Otherwise you can use the `sfconfig prometheus`
CLI command to deploy a tenant-scoped Prometheus instance with the proper label selector configured to scrape only
SF-issued metrics.

Injecting monitoring knowledge into the operator
================================================

So far, we've seen how to deploying our application with an operator allowed us to also pre-configure the monitoring stack.
We're emitting metrics and collecting them, but what should we do with this window on our system?

We should, obviously, define alerts so that we can know when the application is not running optimally, or worse. And as
you probably guessed already, there's a prometheus-operator defined Custom Resource for that: the `PrometheusRule`_.

The resource is very straightforward to use, `as can be seen in the log server controller`_ for example. Once again,
we scope our PrometheusRules to the ``sf-monitoring`` label and they will be picked up automatically by the right Prometheus
instance.

What's great is that with these rules, developers of an operator can inject their knowledge and expertise about an application's
expected behavior. My team and I have been running Zuul and Nodepool at scale for several large deployments for years,
so we know a thing or two about what's interesting to monitor and what should warrant immediate remediation action.
Now we can easily add this knowledge in a way that future deployers can benefit from almost immediately.

.. image:: images/itsbeautiful.jpeg

Next steps
==========

At the time of this writing, there is still a lot of patches in my monitoring stack that need to be merged. Once this is done,
I'd like to experiment further with the following:

Operator metrics
----------------

The `kubebuilder documentation about metrics`_ explains how to publish default performance metrics
for each controller in an operator. It is also possible to add and emit custom metrics.

On a purely operational level, these metrics are less interesting to us than operands metrics. However, it would
probably be good to keep an eye on ticks on `controller_runtime_reconcile_errors_total`_ and
on the evolution of `controller_runtime_reconcile_time_seconds`_ for performance fluctuations.

KEDA
----

This is where the fun begins! The `KEDA operator`_ greatly expands the capabilities of Kubernetes' Horizontal Pod Autoscaler.
While HPA relies on basic metrics like Pod CPU or memory use (or requires some additional effort to work with custom metrics),
KEDA allows you to trigger your autoscaling with a lot more event types.

And among them... `Prometheus queries`_.

We could provide predefined KEDA triggers based on relevant queries like `NotEnoughExecutors`_ to start spawning
new executors when this alert fires.

Log server autoresize
---------------------

So far we have only considered metrics-driven scaling of **pods** horizontally. This works especially well for stateless applications, or
stateful applications that have a strategy to configure the first deployed pod as a primary node or master, and every extra pod as a replica or slave.
But the log server application isn't stateless (logs are stored) and a primary/replicas architecture would be hard, if not impossible, to implement correctly with HTTPD **and**
SSH. And as stated before, Apache and SSH are virtually never bottlenecks for the Log server; but *storage* is. Kubernetes, and OpenShift as well for that
matter, do not seem to address this need for storage autoscaling.

But since we deploy the Log server via an operator, it might be possible to circumvent this limitation like so:

- in the Log server controller's reconcile loop, use the RESTClient library or some other way to query the ``/metrics`` endpoint on the node exporter sidecar, or simply run ``du`` or similar
- compute how much free space is available
- if the value is under 10% for a given period, increase the log server's persistent volume's size by a predefined increment
- reconcile again later to check free space and repeat

If these experimentations are successful, the day to day operation of our Zuul deployments is going to be **so** much easier!

Conclusion
==========

I must say that working with the operator framework and monitoring, while a bit scary initially, is starting to make so much sense in the long run.
I feel like orchestration with Kubernetes and OpenShift is to managing applications what packaging RPMs has been to installing said applications: a lot of effort for
packagers and operator developers, but deployers' lives are made so much easier for it. Kubernetes and OpenShift take it to the next level by adding the opportunity
to inject lifecycle and management "intelligence", leading potentially to applications being able to "auto-pilot", freeing your time to focus on the really cool stuff.

I am really looking forward to experimenting and discovering more of what operators can offer.


.. _work I have done on monitoring operands: https://softwarefactory-project.io/r/q/(topic:prometheus_operator+OR+topic:monitoring)+project:software-factory/sf-operator
.. _SF Operator: https://github.com/softwarefactory-project/sf-operator
.. _prometheus operator: https://prometheus-operator.dev
.. _kubebuilder documentation about metrics: https://book.kubebuilder.io/reference/metrics
.. _controller_runtime_reconcile_errors_total: https://github.com/kubernetes-sigs/controller-runtime/blob/v0.11.0/pkg/internal/controller/metrics/metrics.go#L37
.. _controller_runtime_reconcile_time_seconds: https://github.com/kubernetes-sigs/controller-runtime/blob/v0.11.0/pkg/internal/controller/metrics/metrics.go#L44
.. _Horizontal Pod Autoscaling: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
.. _ensure the right port is declared in the relevant container spec: https://github.com/softwarefactory-project/sf-operator/commit/3197071539ed2837c6abe92aafeb9c5508772005#diff-99cc76ed2f64fcf0aaccc5918907ec2c02b2dd3e6e0ea86d0841b40f0adc8eaeR212
.. _ensure emitting the metrics is enabled in the operand's configuration: https://github.com/softwarefactory-project/sf-operator/commit/b8e6f7bcf65b51a0fb05f97a9295f7f3cb99466e#diff-99cc76ed2f64fcf0aaccc5918907ec2c02b2dd3e6e0ea86d0841b40f0adc8eaeR425
.. _emitting Apache metrics to be scraped by Prometheus: https://www.giffgaff.io/tech/monitoring-apache-with-prometheus
.. _Node Exporter: https://github.com/prometheus/node_exporter#node-exporter
.. _helper function called "MkNodeExporterSideCarContainer": https://softwarefactory-project.io/r/c/software-factory/sf-operator/+/29391/37/controllers/libs/monitoring/monitoring.go#50
.. _within the Log server controller: https://softwarefactory-project.io/r/c/software-factory/sf-operator/+/29391/37/controllers/logserver_controller.go#348
.. _StatsD Exporter: https://github.com/prometheus/statsd_exporter#overview
.. _mapping configuration file: https://softwarefactory-project.io/r/c/software-factory/sf-operator/+/29482
.. _helper function called "MkStatsdExporterSideCarContainer": https://softwarefactory-project.io/r/c/software-factory/sf-operator/+/29391/37/controllers/libs/monitoring/monitoring.go#93
.. _PodMonitor: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#podmonitor
.. _ServiceMonitor: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#servicemonitor
.. _opted to manage PodMonitors in the SF-Operator: https://softwarefactory-project.io/r/c/software-factory/sf-operator/+/29391/37/controllers/libs/monitoring/monitoring.go#176
.. _sfconfig prometheus: https://softwarefactory-project.github.io/sf-operator/cli/#development-related-commands
.. _PrometheusRule: https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#prometheusrule
.. _as can be seen in the log server controller: https://softwarefactory-project.io/r/c/software-factory/sf-operator/+/29370/20/controllers/logserver_controller.go#121
.. _KEDA operator: https://keda.sh
.. _Prometheus queries: https://keda.sh/docs/2.12/scalers/prometheus/
.. _NotEnoughExecutors: https://softwarefactory-project.io/r/c/software-factory/sf-operator/+/29682/1/controllers/zuul.go#420