.. _nodepool3-user:

.. note::

  This is a lightweight documentation intended to get users started with defining
  test nodes. For more insight on what Nodepool can do, please refer
  to its upstream documentation_.

.. _documentation: https://docs.openstack.org/infra/nodepool/feature/zuulv3/


Nodepool3 user documentation
============================

Labels, providers and diskimage are defined in *config/nodepoolV3/*.
All the yaml files present in this directory are merged to create the final
Nodepool configuration. It's recommended to create a file per provider or project
so that it's easier to manage.


Below is an example of a cloud provider configuration and an associated
diskimage/label:

.. code-block:: yaml

  ---
  diskimages:
    - name: centos7
      formats:
        - raw
      elements:
        - centos-minimal
        - nodepool3-minimal
        - sf-zuul3-worker

  labels:
    - name: centos7
      min-ready: 1

  providers:
    - name: nodepool-provider
      cloud: default
      clean-floating-ips: true
      image-name-format: '{image_name}-{timestamp}'
      boot-timeout: 120
      rate: 10.0
      diskimages:
        - name: centos7
      pools:
        - name: main
          max-servers: 20
          networks:
             - workers
          labels:
            - name: centos7
              min-ram: 1024
              diskimage: centos7


Cloud provider tuning
---------------------

`Provider settings <https://docs.openstack.org/infra/nodepool/feature/zuulv3/configuration.html#provider>`_
include:

* **rate**: the delay between each API call, set it to 1 or lower for fast operations.
* **clean-floating-ips**: automatically release all unused floating IP addresses.
* **boot-timeout** : the delay to wait for an instance to start, the default value is 60 seconds.

`Labels settings <https://docs.openstack.org/infra/nodepool/feature/zuulv3/configuration.html#pool-labels>`_
include:

* **boot-from-volume**: Use a volume instead of an ephemeral disk.
* **cloud-image**: Use an externally managed image instead of DIB.


Diskimage elements
------------------

When using **nodepool3-builder**, you can create custom disk images using
diskimage-builder. Refer to the nodepoolV2 :ref:`user documentation<diskimage-elements>`.
