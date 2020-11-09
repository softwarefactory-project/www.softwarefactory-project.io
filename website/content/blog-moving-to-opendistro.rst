Moving to Opendistro for Elasticsearch
######################################

:date: 2020-11-09 10:00
:category: blog
:authors: Daniel Pawlik
:tags: opendistro elasticsearch


This article explains why we choose Opendistro and what we have done
to integrate it in Software Factory.


Why Opendistro?
---------------

The Opendistro ELK stack is a  "community-driven 100% open source distribution
of Elasticsearch with advanced  security, alerting, SQL support,
automated index management, deep performance analysis, and more."

The main reason behind the switch to Opendistro is that
we would like to have a Role Base Access Control (RBAC) which is
provided in Opendistro. With that, we are able to give read-only access to
non-privileged users, so our visualizations, indexes, index patterns and other
components in Elasticsearch and Kibana are pretected.
by third parties.

Before choosing Opendistro, we evaluated the following alternatives:

- Opensource version of Elasticsearch with X-Pack Community Edition
- Secure-Guard
- Readonlyrest

Some of them were not providing enough features, some others had licenses that
are inconvenient for our project. Thats why we chose Opendistro, which comes under
Apache2 license, has a large community for support, and provides multiple features
that we would like to include in the future releases of Software Factory.

The `official documentation for Opendistro for Elasticsearch`_.


.. _`official documentation for Opendistro for Elasticsearch`: https://opendistro.github.io/


Basic authentication
--------------------

There is multiple authentication solutions available in Opendistro.
With Software Factory 3.6 only "basic internal" authentication is enabled.

The authentication configuration can be found in the following directory on your
deployment:

.. code-block:: none

   /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/

in `config.yml` file. Configuration example:

.. code-block:: yaml

   # config.yml
   _meta:
     config_version: 2
     type: config
   config:
     dynamic:
       kibana:
         multitenancy_enabled: false
       http:
         anonymous_auth_enabled: false
         xff:
           enabled: false
       authc:
         basic_internal_auth_domain:
           authentication_backend:
             type: intern
           description: Authenticate via HTTP Basic against internal users database
           http_authenticator:
             challenge: true
             type: basic
           http_enabled: true
           order: 4
           transport_enabled: true

Other available authentication systems are available `here`_ .

.. _`here`: https://opendistro.github.io/for-elasticsearch-docs/docs/security/configuration/configuration/


How to manage users in basic authentication?
--------------------------------------------

By using 'basic authentication', all users are defined in the dedicated file
`internal_users.yml` located in `opendistro_security config directory`.
`More information about the file`_.

.. _`More information about the file`: https://opendistro.github.io/for-elasticsearch-docs/docs/security/configuration/yaml/#internal_usersyml


Adding a new user to internal database
--------------------------------------

In that section, we will add a new user: `kibana` to the internal
database.

.. code-block:: yaml

   # internal_users.yml
   # (...)
   kibana:
     hash: <PASSWORD HASH>
     reserved: true
     backend_roles:
       - kibana_viewer
     description: Kibana viewer user


Generating password to new user
-------------------------------

Opendistro comes with a CLI utility to generate password hashes for users.

Example:

.. code-block:: bash

   /usr/share/elasticsearch/plugins/opendistro_security/tools/hash.sh -p <MY PASSWORD>

The generated hash should be added into the `internal_users.yml` file as the "hash" property
for the user.

To apply that change, you need to run `securityadmin.sh` script.


Roles
-----

The roles are described in `roles.yml` file located in `opendistro_security
config directory`.
In this file, you are able to create your own roles, with defined rules.
For example, it will be good set `kibana` read only user permission limitation
to read-only access.

.. code-block:: yaml

   # roles.yml
   # (...)
   kibana_viewer:
     reserved: true
     cluster_permissions:
     - "cluster_composite_ops_ro"
     index_permissions:
     - index_patterns:
       - "?kibana*"
       - "?kibana"
       - "logstash-*"
       allowed_actions:
       - "read"
       - "get"
       - "search"
       - "indices:data/write/update"
       - "indices:data/write/index"
       - "indices:data/write/bulk*"
     tenant_permissions: []

The `kibana_viewer` user has `limited access`_ to run `allowed_actions`_
on current set `index_patterns`. The `tenant_permissions` are in that example
set to the empty list, so it will be applied on all available tenants.
The `cluster_permissions` is a Opendistro cluster-level `dedicated roles`_.

.. note::

   In Software Factory 3.6, the `kibana` user has the `kibana_viewer` role, which
   is the same as in this example. It is because multiple automation is raising
   problems in access to the `.kibana` index in Elasticsearch.
   The `kibana_read_only` role (which you can find in the `predefined roles` section)
   is only allowed to see dashboards and visualization and it does not have
   access to searches in the Elasticsearch, that's why we are not using the
   predefined role in SF 3.6.
   If the above `kibana_viewer` role gives too many permissions to the
   user, you can always check sample `read-only` roles with bulk access
   that are described in `this document`_.

.. _`limited access`: https://opendistro.github.io/for-elasticsearch-docs/docs/security/access-control/permissions/#indices
.. _`allowed_actions`: https://opendistro.github.io/for-elasticsearch-docs/docs/security/access-control/default-action-groups/#index-level
.. _`dedicated roles`: https://opendistro.github.io/for-elasticsearch-docs/docs/security/access-control/default-action-groups/#cluster-level
.. _`this document`:  https://opendistro.github.io/for-elasticsearch-docs/docs/security/access-control/users-roles/#sample-roles


Predefined roles
----------------

In Opendistro, there are multiple roles defined with `dedicated usage`_.
For example `kibana_read_only` role (that should be used also with `kibana_user`
role) gives user only access to the dashboards and visualization. The user
is not able to search or make some API queries.

.. _`dedicated usage`: https://opendistro.github.io/for-elasticsearch-docs/docs/security/access-control/users-roles/#predefined-roles


Role mappings
-------------

After creating roles, user can be associated using role mapping,
for example::

.. code-block:: yaml

   # role_mappings.yml
   # (...)
   kibana_viewer:
     reserved: false
     backend_roles:
     - "kibana_viewer"
     description: "Maps kibana viewer role"

In that example, the `kibana_viewer` role mapping is using `kibana_viewer`
role that was described in `roles.yml` file. For more information, check the
`Roles` section.


What if I have many projects?
-----------------------------

Software Factory 3.6 only configures one tenant: `global` and
it also disables multi-tenancy (check Kibana configuration file).
This `document`_ explains how to configure multi-tenancy.

.. _`document`: https://opendistro.github.io/for-elasticsearch-docs/docs/security/access-control/multi-tenancy/#add-tenants


I made a change, but they are not applied - securityadmin.sh script
-------------------------------------------------------------------

To apply created changes, you need to execute the `dedicated script`_ script.
It is the most important step that you should not forget after doing some
changes.

In the Software Factory 3.6, the command below will setup the `securityadmin.sh`
script. What you need to do is to execute it on the Elasticsearch host.

.. code-block:: bash

   /usr/share/elasticsearch/plugins/opendistro_security/tools/securityadmin.sh   \
     -cd /usr/share/elasticsearch/plugins/opendistro_security/securityconfig/  \
     -icl -nhnv -cacert /etc/elasticsearch/certs/localCA.pem  \
     -cert /etc/elasticsearch/certs/elasticsearch-admin.crt  \
     -key /etc/elasticsearch/certs/elasticsearch-admin.key    \
     -h $(hostname)

.. _`dedicated script`: https://opendistro.github.io/for-elasticsearch-docs/docs/security/configuration/generate-certificates/#run-securityadminsh


Elasticsearch user password in Software Factory
-----------------------------------------------

Sfconfig automatically generate users for each service that
is using Elasticsearch. The passwords are saved in Software Factory
the bootstrap-data:

.. code-block:: none

   /var/lib/software-factory/bootstrap-data/secrets.yaml


.. note::

   All entries that are beginning with `elasticsearch_` preffix and ending with
   `password` are able to change. If you change some passwords there, you need
   to run sfconfig tool to apply the changes or read section
   `Generating password to new user`.


Does Opendistro affect other services?
--------------------------------------

By changing the ELK stack to the Opendistro, some services require to
change the configuration:

- logstash - the service requires to add `ilm_enabled` `option set` to False.

.. code-block:: none

   output {
     elasticsearch {
       hosts => ['localhost:9200']
       index => "logstash-%{+YYYY.MM.dd}"
       user => 'logstash'
       password => 'password'
       ssl => true
       ssl_certificate_verification => true
       ilm_enabled => false
     }
   }

- curator - the curator tool requires to provide authentication credentials.

.. code-block:: yaml

   client:
     hosts:
       - localhost:9200
     timeout: 30
     use_ssl: True
     ssl_no_validate: False
     certificate:  /etc/elasticsearch/certs/localCA.pem
     http_auth: curator:password

- RepoXplorer- same as `curator` tool, it requires to set proper credentials.

.. code-block:: python

   elasticsearch_user = 'repoxplorer'
   elasticsearch_password = 'password'

.. _`option set`: https://opendistro.github.io/for-elasticsearch-docs/docs/troubleshoot/#logstash


Default Opendistro settings
---------------------------

By default Opendistro is running the `install_demo_configuration.sh` script
on installing the package. The script is creating default environment,
configuration for Kibana and Elasticsearch service (also generating the
self-signed certificates).
It is recommended to disable the demo configuration on production
environment (like we do in Software Factory).


Summary
-------

The Opendistro for Elasticsearch is a good solution to enable RBAC control.
We successfully integrated it in Software Factory 3.6 to protect the user
index, and we were able to implement a transparent upgrade path.
