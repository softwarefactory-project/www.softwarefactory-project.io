Delegating maintenance actions with Zuul - part 1
###################################################

:date: 2019-08-01
:category: blog
:authors: Matthieu Huin

`Zuul's <https://zuul-ci.org>`_ CLI Client provides several actions that can help
debugging kinks along its integration pipelines. These actions were until now only
available to operators of a Zuul deployment, meaning that project members were
dependent on the availability of an operator to help them sort problems out. I
have been working on scoping these actions to tenants, with support for
authentication and authorization within Zuul itself. This means that operators
can now delegate the ability to perform these actions temporarily as they see fit.

This series of articles will explain how these tenant-scoped actions work, and
how to set up a Zuul deployment to delegate these actions.

Zuul's Client Toolset
---------------------

Zuul operators can perform maintenance actions thanks to its CLI client. Here is
a non exaustive list of some of the most useful actions available for debugging:

* `**dequeue** a build set <https://zuul-ci.org/docs/zuul/admin/client.html#dequeue>`_:
  this action lets an operator manually stop a running build. This can be done
  when a build is stuck in some form of infinite loop, or is known to be failing
  for reasons unrelated to proper testing. This can free precious resources quickly.
* `**auto-hold** a node set <https://zuul-ci.org/docs/zuul/admin/client.html#autohold>`_:
  when running jobs on volatile resources like containers or virtual machines, usually
  Zuul would destroy these resources at the end of the run, regardless of the
  results. The ``autohold`` action notifies Zuul that a node set must be kept on
  hold after a job's failure. This will allow an operator to investigate problems
  directly on the node set, if these issues are hard to reproduce otherwise.
* `**enqueue** a build set <https://zuul-ci.org/docs/zuul/admin/client.html#enqueue>`_:
  this action lets an operator manually "replay" a previous build. This is especially
  useful when a problem was fixed with a given job, but the trigger that would start
  the build anew is hard or impossible to reproduce; for example a build in a
  ``periodic`` pipeline, or a build triggered in a ``release`` pipeline as a
  tag cannot be recreated.

JSON Web Tokens
---------------

Zuul's authentication and authorization rely on the `**JSON Web Token (JWT)**
standard <https://jwt.io/introduction/>`_. This standard defines a way to exchange
information between parties securely and in a lightweight manner, and is also well
suited for consumption by web-based services. The information is shared as a JSON
payload that is signed digitally to protect from data tampering.

A JWT consists of three parts that are Base64-encoded and separated by dots:

* the **header**, a JSON dictionary stating that the token is a JWT, and which
  algorithm was used to sign the payload. The JWT standard supports several
  signing algorithms such as HMAC SHA256, and also asymmetrical encryption like
  RSA.
* the **payload**, a free-form JSON dictionary containing the actual information
  to share. Some of the keys in the payload are standard, like **iss** (the
  entity issueing the token), **exp** (the expiry time of the token) and **aud**
  (the intended recipient of the token), but as many keys and values can be added
  to the payload as needed. When using JWTs with Zuul, the custom **zuul.admin**
  key can be set to convey information about which tenants the token bearer is
  allowed to perform maintenance actions on. In the JWT standard, the key-value
  pairs are called **claims**.
* the **signature** takes the Base64-encoded header and payload, and signs them
  using the algorithm in the header and a secret.

Note that the token is only *signed*, not *encrypted*. The JWT standard is not
meant to hold sensitive information like passwords.

JWTs are passed to Zuul's REST API as the "Authorization" header.

Configuring an authenticator in Zuul
------------------------------------

Let's configure Zuul so that operators can generate JWTs that can be used to
perform maintenance actions at tenant level. In order to do so, we must first
add an **authenticator** in Zuul's configuration file:

.. code::

  [auth zuul_operator]
   driver=HS256
   allow_authz_override=true
   realm=zuul.example.com
   client_id=zuul.example.com
   issuer_id=zuul_operator
   secret=NoDanaOnlyZuul
   token_expiry=36000

This snippet, when added to ``zuul.conf``, declares an authenticator called
"zuul_operator". It uses the symmetrical signing algorithm *HS256*, where the secret
can be any type of password or passphrase. This is the
simplest way to get started, but it is also possible to use asymmetrical algorithms;
you will however need to generate a pair of RSA keys on your own. For more
information on the different algorithms available and how to configure them, see `Zuul's documentation
<https://zuul-ci.org/docs/zuul/admin/components.html#driver-specific-attributes>`_.

The ``allow_authz_override`` parameter must be set to true, so that operator-generated
tokens can override any pre-existing authorization rules (we'll explain
Zuul's authorization rules in the next article of the series). ``client_id`` and
``issuer_id`` are the expected values of the token's ``aud`` and ``iss`` claims
respectively. ``token_expiry`` is an extra, optional security to ensure that tokens cannot
be active for more than that value in seconds after being issued (thus the JWT
must include the **iat**, or "issued at", claim).

The ``realm`` parameter is only useful when emitting error messages, when an
incorrect token is presented.

Once you are done with editing zuul.conf, restart the zuul-web service to load
the authenticator.

Generating a JWT for a user
---------------------------

An operator can simply generate a token using Zuul's CLI. You only need to specify
the authenticator to use, the scoped tenant, and a user name (for traceability
in logs only, since Zuul does not have a user backend):

.. code::

   $ zuul create-auth-token --auth-config zuul_operator --tenant tenantA --user user1

The output is what the "Authorization" header value should be when querying
Zuul's REST API manually; the JWT itself is right after "Bearer":

.. code::

   Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE1NjQ3MDAxNzIuMDQxNzc0MywiZXhwIjoxNTY0NzAwNzcyLjA0MTc3NDMsImlzcyI6Inp1dWxfb3BlcmF0b3IiLCJhdWQiOiJ6dXVsLmV4YW1wbGUuY29tIiwic3ViIjoidXNlcjEiLCJ6dXVsIjp7ImFkbWluIjpbInRlbmFudEEiXX19.l8PMwEWgtgqqm95uSlwFaUXc97pnvow0O4IGangX3OQ

If we `decode the token <https://jwt.io/#debugger>`_, this is what we find in
the payload:

.. code::

    {
     "exp": 1564701158.2460928,
     "iss": "zuul_operator",
     "aud": "zuul.example.com",
     "sub": "user1",
     "zuul": {
       "admin": [
         "tenantA"
       ]
     }
    }

The claim ``zuul.admin`` contains the list of tenants on which maintenance
actions can be performed with this token.

The token must then be transmitted to the user out-of-band. Note that this is a
bearer token, so anybody can use the JWT to perform actions that will potentially
impact Zuul's regular operations. A good way to mitigate this problem is to
always limit the scope to one single tenant, and to use as short an expiry time
as possible for generated tokens.

Using the JWT
-------------

As a user, there are two ways to consume the JWT once it has been issued:

Direct API calls
****************

We can use cURL to dequeue the buildset started for tenant **tenantA**'s project
**org/project1** from the periodic pipeline:

.. code::

   JWT=Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE1NjQ3MDAxNzIuMDQxNzc0MywiZXhwIjoxNTY0NzAwNzcyLjA0MTc3NDMsImlzcyI6Inp1dWxfb3BlcmF0b3IiLCJhdWQiOiJ6dXVsLmV4YW1wbGUuY29tIiwic3ViIjoidXNlcjEiLCJ6dXVsIjp7ImFkbWluIjpbInRlbmFudEEiXX19.l8PMwEWgtgqqm95uSlwFaUXc97pnvow0O4IGangX3OQ
    curl -X POST -H "Authorization: ${JWT}" \
    -d '{"ref": "refs/heads/stable", "pipeline": "periodic"}' \
    https://zuul.example.com/api/tenant/tenantA/project/org/project1/dequeue

Zuul's REST API's documentation is a work-in-progress, but you can find the latest
prototype of the documentation in the `OpenAPI <https://github.com/OAI/OpenAPI-Specification>`_
format `in this code review <https://review.opendev.org/#/c/674257/>`_.

Using the CLI
*************

Or we can use Zuul's CLI, which is much simpler :) You need to install the CLI
first; you should do so in a virtualenv (see `this documentation <https://docs.python-guide.org/dev/virtualenvs/>`_
for example if you need help with that).

.. code::

   pip install zuul

(Note that doing so pulls down the whole zuul project, but it is the only way
at the moment to install the client)

While it is possible to specify Zuul's base URL and SSL settings through command
line arguments, if you're going to perform maintenance actions more than once it
may be wiser to prepare a configuration file:

.. code::

    [webclient]
     url=https://zuul.example.com
     verify_ssl=true

The only two available options are self-explanatory.

The previous REST call can be then performed this way with the CLI:

.. code::

    JWT=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE1NjQ3MDAxNzIuMDQxNzc0MywiZXhwIjoxNTY0NzAwNzcyLjA0MTc3NDMsImlzcyI6Inp1dWxfb3BlcmF0b3IiLCJhdWQiOiJ6dXVsLmV4YW1wbGUuY29tIiwic3ViIjoidXNlcjEiLCJ6dXVsIjp7ImFkbWluIjpbInRlbmFudEEiXX19.l8PMwEWgtgqqm95uSlwFaUXc97pnvow0O4IGangX3OQ
    zuul -c /path/to/zuul.conf --auth-token $JWT dequeue --tenant tenantA \
    --project org/project1 --pipeline periodic --ref refs/head/stable


.. note::

   You have to remove the "Bearer" part from the token this time.

Conclusion
----------

With JWT support, Zuul operators can now easly delegate maintenance actions at tenant
level to others when needed. This article was a short introduction to get operators
started with this new feature, with a minimal setup.

In the next article, we will expand on this and see how operators can configure
access rules and apply them to tenants, so that access can be filtered through
conditions on JWT claims.

In the meantime, if you'd like to learn more about the feature, you can refer to
`Zuul's section of the documentation about the tenant-scoped REST API
<https://zuul-ci.org/docs/zuul/admin/tenant-scoped-rest-api.html>`_.
