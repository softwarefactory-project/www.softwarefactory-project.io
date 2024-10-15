Embedded MQTT broker
--------------------

Firehose is an embedded MQTT broker that concentrates events from services
that are run within your Software Factory deployment.

See the :ref:`Firehose user documentation<firehose-user>` for more details.


Activating Firehose
^^^^^^^^^^^^^^^^^^^

To activate firehose, just add the "firehose" role to a host in the :ref:`architecture file<architecture>`,
This will automatically enable the reporters for active services that support them.

Security
^^^^^^^^

Only the service user can publish events to the broker. All other accesses will be
read-only.
