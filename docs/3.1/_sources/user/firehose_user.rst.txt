.. _firehose-user:

Firehose
========

Firehose is an embedded MQTT broker that concentrates
events from services run within a Software Factory
deployment, making it easy for external processes to
consume these events and act upon them.

It is not possible to publish messages on the firehose outside of
the predefined services, however anyone is allowed to subscribe
anonymously to the feed by using the MQTT protocol.

Services supported
------------------

================= ============= ================
  Service           Topic         Source
================= ============= ================
 Gerrit             gerrit        `germqtt`_
 Zuul               zuul          `reporter`_
================= ============= ================

.. _germqtt: http://git.openstack.org/cgit/openstack-infra/germqtt/
.. _reporter: https://zuul-ci.org/docs/zuul/admin/drivers/mqtt.html

Events published
----------------

Events are published in JSON format. The payload is specific to each event.

Gerrit
......

Every patchset-related events are published, similarly to the `gerrit stream-events`
command. A full description of each event type can be found here:
https://gerrit-review.googlesource.com/Documentation/cmd-stream-events.html

Zuul
....

Every buildset results are published. A full description of the events can
be found here:
https://zuul-ci.org/docs/zuul/admin/drivers/mqtt.html#message-schema


Subscribing to events
---------------------

Simple CLI example
..................

The mosquitto project provides a CLI subscriber client that can be used to easily
subscribe to any topic and receive the messages. On debian based distributions it
is included in the **mosquitto-clients** package; on Fedora or CentOS it can be found
in the **mosquitto** package.
For example, to subscribe to every topic on the firehose you would run::

    mosquitto_sub -h firehose.fqdn --topic '#'

You can adjust the value of the topic parameter to subscribe only to a specific service.

Simple desktop notifier
.......................

If you are using a GTK based desktop
environment such as gnome, this script can be used
to get notifications on specific, customizable events from the firehose:

https://softwarefactory-project.io/r/gitweb?p=software-factory%2Fsf-desktop-notifications.git;a=summary

Please see the project's README for more information.
