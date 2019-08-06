Delegating maintenance actions with Zuul - part 2
###################################################

:date: 2019-09-24
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

In `part 1 <{filename}/authNZ-with-zuul-part1.rst>`_ we introduced
the `JWT standard <https://jwt.io/introduction/>`_ and described the simplest way to
get started with delegating maintenance actions. Let's expand on this with a
closer look at Zuul's access rules.

JWT and Claims
--------------

As we saw in part 1, a requirement of the JWT standard is that the contents of a token
be signed. JWTs can be issued by a trusted service like an identity provider,
and then consumed safely by other services such as Zuul, as long as the signature
can be verified.

.. note::

   The JWT standard requires signing the payload, but that doesn't mean that the
   data is encrypted. Actually, anybody with access to the token can read its
   payload, as it is simply base64-encoded. No sensitive data should be carried
   in a JWT.

The payload of a JWT can be set to anything we want, except for a few standard claims.
This means a JWT can hold specific information about its bearer
such as a username, email address or phone numbers; or attributes and properties
such as groups, resources ownership, or roles within an organization.

By setting access rules, an operator can ensure that tenant-scoped
maintenance actions are allowed only for token bearers where the token's claims
verify a specific set of conditions.

Zuul's Access Rules
--------------------------

Access rules, as they are defined in `Zuul's manual <https://zuul-ci.org/docs/zuul/admin/tenants.html#admin-rule-definition>`_,
are "a set of conditions the claims of a JWT must match in order to be allowed
to perform protected actions at a tenant's level". These rules are described as
YAML objects and must be set in Zuul's tenant configuration file.

Here's what a rule definition looks like:

.. code::

    - admin-rule:
        name: first_rule_of_fight_club
        conditions:
          - speak: false

The **name** is used for later reference to the rule in the tenant configuration.

The **conditions** is a list of, unsurprisingly, conditions on some claims in the
JWT. They're written in the form *<claim name>*: *<claim value>*.

Depending on the type of the claim in the JWT (list or string), Zuul's
authorization engine will treat the condition as either "membership" (list) or
"strict equality" (string).

Advanced Rules
***************

Some JWTs can have complex structures such as nested dictionaries. Zuul's
authorization engine can match these by using the XPath format, for example:

.. code::

    - admin-rule:
        name: example_of_xpath_rule
        conditions:
           - resources_access.account.roles: admin

will match successfully on the following complex JWT payload:

.. code::

    {
     'iss': 'columbia_university',
     'aud': 'my_zuul_deployment',
     'exp': 1234567890,
     'iat': 1234556780,
     'sub': 'venkman',
     'resources_access': {
         'account': {
             'roles': ['ghostbuster', 'admin']
         }
       },
    }

Basic boolean operations on conditions is supported as well:

AND
,,,

example:

.. code::

    - admin-rule:
        name: AND_RULE
        conditions:
          - iss: my_issuer
            myclaim: myvalue

OR
,,

example:

.. code::

    - admin-rule:
        name: OR_RULE
        conditions:
          - iss: my_issuer
          - myclaim: myvalue

zuul_uid
********

Zuul's authorization engine allows operators to define a special claim called
**zuul_uid** mapped to an arbitrary claim name of the operator's choosing, by
default the **sub** claim. This is useful when the service emitting JWTs sets
the sub claim as a hard-to-read user id like a hash; and another, human-friendlier
claim can be used to refer to a user.

Adding Rules to a Tenant
------------------------

Once you are satisfied with your rules, you can assign them to any tenant with
the **admin-rules** attribute in your tenant configuration:

.. code::

    - tenant:
        name: my-tenant
        admin-rules:
          - rule1
          - rule2

Now when a user tries to use the REST API to trigger a maintenance action on
*my-tenant*, she will be allowed to do so if her token matches *rule1* or *rule2*.

.. note::

   As we mentioned in part 1, authenticators can be configured to allow overriding
   a tenant's rules if the ``allow_authz_override`` option is set to True. In that
   case, any JWT with the ``zuul.admin`` claim set to a given tenant will override
   its access rules.

Generating a custom JWT
-----------------------

Now that we can use custom claims for authorization, we need a way to generate
custom JWTs. This can be done in python with the `pyjwt library <https://pyjwt.readthedocs.io/en/latest/>`_,
for example:

.. code::

    import jwt
    import time
    token = {'sub': 'user1',
             'iss': 'my_issuer',
             'aud': 'zuul',
             'iat': time.time(),
             'exp': time.time() + 300,
             'my_claim': 'my_value'}
    print(jwt.encode(token, 'secret', algorithm='HS256'))

Online resources like https://jwt.io are also available to generate, decode and
debug JWTs.

Conclusion
----------

In this article we've seen how to define and use access rules with Zuul. We've also
explained how to generate JWTs with custom claims for use with these rules. In the
next article of this series, we will discuss how to use an identity provider with
Zuul to authenticate and authorize users. Stay tuned!
