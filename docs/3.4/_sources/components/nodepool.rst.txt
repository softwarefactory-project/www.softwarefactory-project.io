.. _nodepool_components:

.. TODO: describe all nodepool services

Test instances management
-------------------------

`Nodepool <https://docs.openstack.org/infra/nodepool>`_ is
the service in charge of creating tests environment. It supports 5 types of
drivers to create instances:

* Openstack cloud
* Static node
* OpenShift
* Amazon AWS EC2
* OpenContainer (runC) (deprecated)

It is designed to handle the life cycle of build resources (creation, provision,
assignation and destruction).
