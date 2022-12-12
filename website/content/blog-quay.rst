Replacing old container registry with Quay
##########################################

:date: 2022-12-12
:category: blog
:authors: Daniel

What is Quay ?
==============

A distributed and highly available container image registry.

Additional services
===================

The Quay service can communicate with additional services:

- `clair <https://www.redhat.com/en/topics/containers/what-is-clair>` - is an open source project which provides a tool to monitor the
  security of your containers through the static analysis of vulnerabilities
  in appc and docker containers. [1].
- `quay-mirror <https://access.redhat.com/documentation/en-us/red_hat_quay/3/html/manage_red_hat_quay/repo-mirroring-in-red-hat-quay>` - it is a service
  that provides mirroring functionality of external repository and pull
  it into current one.


How to deploy ?
===============

The service can be deployed by using dedicated role provided in `software-factory/sf-infra project<https://softwarefactory-project.io/r/plugins/gitiles/software-factory/sf-infra/+/refs/heads/master/roles/rdo/quay/>`
It deploys automatically required services such as:

- reddis - an in-memory data structure store, used as a distributed,
  in-memory key–value database, cache and message broker, with
  optional durability,
- PostgreSQL - open source object-relational database.


Below there is an example of the playbook how to deploy Quay with
Clair service and Quay mirror.

.. raw:: yaml

  - hosts: quay.dev
    vars:
      fqdn: quay.dev
      self_signed_certs: true
      initial_config: false
      quay_validate_cert: false
      # NOTE: password needs to be at least 8 characters
      quay_users:
        admin:
          email: admin@somemail.com
          password: password
          token: ""
        someuser:
          email: someuser@someemail.com
          password: password
          token: ""
    tasks:
      - name: Setup quay
        include_role:
          name: quay
          tasks_from: main.yml
    roles:
      - hostname


Quay - organizations, users, roles...
=====================================

Organizations
-------------

Organizations provide a way of sharing repositories under a common
namespace that does not belong to a single user, but rather to many
users in a shared setting (such as a company).

Teams
-----

Organizations are organized into a set of Teams which provide access
to a subset of the repositories under that namespace

Users, robots and roles
-----------------------

TBD


Quay user automation
====================

Python Quay tool
----------------

TBD

Swagger
-------

Swagger is a suite of tools for API developers from SmartBear Software and
a former specification upon which the OpenAPI Specification is based.

You can start running the Swagger tool in the container and communicate
with Quay API.

How to start Swagger:

.. raw:: shell

   # Start swagger container
   podman run -p 8888:8080 -e API_URL=https://quay.dev/api/v1/discovery docker.io/swaggerapi/swagger-ui

   # If you are using local instance with firewall rules, you can tunel
   # the ssh connection and redirect the port
   # OPTIONAL
   ssh -L 8888:localhost:8888 centos@quay.dev

After running abowe commands, you should be able to reach the swagger
Web UI interface on URL: `http://quay.dev:8080`

Example how to automate Quay organization deployment base on TripleO release
----------------------------------------------------------------------------

TBD


Documentation
-------------

Quay provides documentation that has also troubleshooting chapter.
The documentation you can find in `here <https://docs.quay.io/>`.
