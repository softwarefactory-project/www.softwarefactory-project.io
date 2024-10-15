.. _tenant_deployment:

Deploy a tenant instance of Software Factory
--------------------------------------------

A tenant SF is an instance that does not run Zuul services. Zuul
services (Zuul, Nodepool) will be shared with a Master SF. Users of a
tenant SF benefit from their own SF services like Gerrit or ELK.

In this guide, we will deploy a SF for a tenant. This tenant
will run Gerrit. Some tasks will be executed on the Tenant SF
and some others on the master SF.

Deploy the minimal tenant architecture
......................................

On a CentOS-7 system, deploy the tenant minimal architecture:

.. code-block:: bash

  yum install -y https://softwarefactory-project.io/repos/sf-release-3.4.rpm
  yum install -y sf-config
  cp /usr/share/sf-config/refarch/tenant-minimal.yaml /etc/software-factory/arch.yaml
  sed -i '/      - cauth/a\      - gerrit\n      - gitweb' /etc/software-factory/arch.yaml

Edit /etc/software-factory/sfconfig.yaml to set the fqdn for the deployment and add:

.. code-block:: yaml

  tenant-deployment:
    name: tenant-sf
    master-sf: https://master-sf.com

.. note::

  if master-sf instance use self-signed certificates, you should copy
  '/etc/pki/ca-trust/source/anchors/localCA.pem' from master-sf to
  '/etc/pki/ca-trust/source/anchors/master-sf.pem' on the tenant instance, then run
  'update-ca-trust' to trust this CA.

.. note::

  If the tenant config repositories are on Github, follow :ref:`Create a config and
  jobs repository<create_config_job_repos>` to create the projects and the section
  :ref:`Update the configuration<update_the_configuration>` without the
  github_connection section since it is already set in the main instance.

Then run sfconfig:

.. code-block:: bash

  sfconfig

Add the new tenant on the Master SF
...................................

Define the tenant's default connection in /etc/software-factory/sfconfig.yaml:

.. code-block:: yaml

  gerrit_connections:
    - name: tenant-sf
      hostname: tenant-sf.com
      port: 29418
      puburl: https://tenant-sf.com/r/
      username: zuul
      default_pipelines: false

Then run sfconfig

.. code-block:: yaml

  sfconfig --skip-install

.. note::

  if tenant-sf instance use self-signed certificates, you should copy
  '/etc/pki/ca-trust/source/anchors/localCA.pem' from tenant-sf to
  '/etc/pki/ca-trust/source/anchors/tenant-sf.pem' on master-sf's zuul-executor
  instances, then run 'update-ca-trust' to trust this CA.

Define the new tenant inside the resources. Create the following file
config/resources/tenant.yaml:

.. code-block:: yaml

  resources:
    tenants:
      tenant-sf:
        description: "The new tenant"
        url: "https://tenant-sf.com/manage"
        default-connection: tenant-sf

.. code-block:: bash

  git add resources/tenant.yaml && git commit -m"Add new tenant" && git review

Once the change is approved, merged and the *config-update* finished with success,
operator can run sfconfig on the tenant SF instance.


Finalize the tenant SF configuration
....................................

The Master is now configured and know about the new tenant, then
a final sfconfig run on the tenant SF will finalize the pairing.

.. code-block:: bash

  sfconfig --skip-install


Workflow details
................

A tenant SF gets its own SF config repository. The tenant can manage its own resources
like CRUD on Gerrit repositories. *config-check* and *config-update* jobs are triggered
during a change lifecycle for the tenant's config repository. Both are executed on
the Master SF's Zuul executor.
