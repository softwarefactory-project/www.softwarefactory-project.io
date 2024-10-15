.. _metrics_components:

System and Services metrics
===========================

On Software Factory, a metric stack could be deployed to provide system and
services metrics (zuul and nodepool). When the metrics stack is activated, the
following components are deployed:

* `Telegraf <https://www.influxdata.com/time-series-platform/telegraf/>`_: a
  plugin-driven server agent for collecting and reporting metrics.
* `Influxdb <https://www.influxdata.com/time-series-platform/influxdb/>`_: a time series database for storing metrics.
* `Grafana <https://grafana.com/>`_: a platform for analytics and monitoring.

.. image:: ../operator/imgs/metrics/grafana_dashboard.png
   :scale: 50 %

As operator, you can understand how the metrics are implemented on Software
Factory. To activate metrics, follow the :ref:`operator documentation
<metrics_operator>`.

As users, you can have a look to the :ref:`user documentation <metrics_user>`
to understand how to use or add dashboards.
