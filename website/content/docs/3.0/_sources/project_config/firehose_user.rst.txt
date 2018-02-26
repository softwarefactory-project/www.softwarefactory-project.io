:orphan:

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
 Jenkins [1]_       zuul_jobs     `MQTT notification plugin`_  and "firehose-zuul" predefined publisher
 Nodepool           nodepool      `ochlero`_
 Zuul               zuul          `ochlero`_
================= ============= ================

.. [1] For jobs managed through the config repository.
.. _germqtt: http://git.openstack.org/cgit/openstack-infra/germqtt/
.. _`MQTT notification plugin`: https://wiki.jenkins-ci.org/display/JENKINS/MQTT+Notification+Plugin
.. _ochlero: https://pypi.python.org/pypi/ochlero

Events published
----------------

Events are published in JSON format. The payload is specific to each event.

Gerrit
......

Every patchset-related events are published, similarly to the `gerrit stream-events`
command. A full description of each event type can be found here:
https://gerrit-review.googlesource.com/Documentation/cmd-stream-events.html

Jenkins
.......

An event is published whenever a Zuul build ends. It publishes the result of the
build, and the Zuul parameters it was launched with:

================== ===========================================
 Key                Value
================== ===========================================
 TIMESTAMP          The Epoch timestamp of the event
 ZUUL_BRANCH        The branch being tested
 ZUUL_PIPELINE      The name of the destination pipeline
 ZUUL_CHANGE        The gerrit review ID
 ZUUL_CHANGES       the long gerrit ID of the change
 ZUUL_PATCHSET      The review patchset version number
 ZUUL_CHANGE_IDS    ZUUL_CHANGE,ZUUL_PATCHSET
 ZUUL_COMMIT        The commit id of the change
 ZUUL_REF           The git reference of the change
 ZUUL_URL           The url used by Zuul to checkout repositories
 ZUUL_PROJECT       The repository on which the review applies
 ZUUL_UUID          Internal Zuul job UUID
 build              The Jenkins build number
 job                The job's name
 node               The id of the node on which the job was executed
 status             The result of the job build
================== ===========================================

Nodepool
........

The following events are published:

node creation
#############

================== ===========================================
 Key                Value
================== ===========================================
 EVENT              CREATE
 HOSTNAME           The hostname
 TIMESTAMP          The Epoch timestamp of the event
 IMAGE              The image used to create the node
 NODE_ID            The nodepool node ID
 PROVIDER           The cloud provider on which the node was created
================== ===========================================

node ready
##########

================== ===========================================
 Key                Value
================== ===========================================
 EVENT              READY
 NODE_ID            The nodepool node ID
 TIMESTAMP          The Epoch timestamp of the event
================== ===========================================

node ready in the orchestrator
##############################

================== ===========================================
 Key                Value
================== ===========================================
 EVENT              READY_ORCHESTRATOR
 NODE_ID            The nodepool node ID
 TIMESTAMP          The Epoch timestamp of the event
 ORCHESTRATOR       The name of the orchestrator (Jenkins)
================== ===========================================

node deleted
############

================== ===========================================
 Key                Value
================== ===========================================
 EVENT              DELETED
 NODE_ID            The nodepool node ID
 TIMESTAMP          The Epoch timestamp of the event
================== ===========================================

node deleted in the orchestrator
################################

================== ===========================================
 Key                Value
================== ===========================================
 EVENT              DELETED_ORCHESTRATOR
 NODE_ID            The nodepool node ID
 TIMESTAMP          The Epoch timestamp of the event
 ORCHESTRATOR       The name of the orchestrator (Jenkins)
================== ===========================================

Zuul
....

The following events are published:

Job moved to any pipeline
#########################

================== ===========================================
 Key                Value
================== ===========================================
 EVENT              ADD_TO_PIPELINE
 PIPELINE           The name of the destination pipeline
 TIMESTAMP          The Epoch timestamp of the event
 ZUUL_CHANGE        The gerrit review ID
 ZUUL_PATCHSET      The review patchset version number
 ZUUL_CHANGE_IDS    ZUUL_CHANGE,ZUUL_PATCHSET
 ZUUL_PROJECT       The repository on which the review applies
================== ===========================================

Job launched
############

================== ===========================================
 Key                Value
================== ===========================================
 EVENT              LAUNCH_JOB
 TIMESTAMP          The Epoch timestamp of the event
 ZUUL_CHANGE        The gerrit review ID
 ZUUL_PATCHSET      The review patchset version number
 ZUUL_CHANGE_IDS    ZUUL_CHANGE,ZUUL_PATCHSET
 ZUUL_UUID          Internal Zuul job UUID
 JOB_NAME           The name of the job launched
================== ===========================================

Build started
#############

================== ===========================================
 Key                Value
================== ===========================================
 EVENT              START_BUILD
 TIMESTAMP          The Epoch timestamp of the event
 ZUUL_UUID          Internal Zuul job UUID
 JOB_NAME           The name of the job launched
================== ===========================================

Build result
############

================== ===========================================
 Key                Value
================== ===========================================
 EVENT              BUILD_RESULT
 TIMESTAMP          The Epoch timestamp of the event
 ZUUL_UUID          Internal Zuul job UUID
 JOB_NAME           The name of the job launched
 RESULT             Either SUCCESS or FAILURE
================== ===========================================

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
