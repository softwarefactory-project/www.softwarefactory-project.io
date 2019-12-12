.. _authentication:

Authentication
--------------

Software Factory supports several authentication backends.
The `Cauth <https://softwarefactory-project.io/r/gitweb?p=software-factory/cauth.git;a=shortlog;h=HEAD>`_
component is used to enforce all authenticated HTTP access.



Single Sign On
^^^^^^^^^^^^^^

Software Factory provides a unified authentication for services such as Gerrit.
Logging out from one service logs you out from other services as well.

Currently SF provides five kinds of backends to authenticate:

* Oauth2 for Github, Google and Bitbucket
* OpenID (e.g. for Launchpad)
* local user database hosted in the managesf node
* LDAP backend
* SAML2

.. image:: ../imgs/login.jpg


Admin user
^^^^^^^^^^

The admin user is hard coded and only the password can be defined.
To change the admin user password, edits sfconfig.yaml:

.. code-block:: yaml

  authentication:
    admin_password: userpass



OAuth2-based authentication
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Software Factory allows authentication with several OAuth2-based identity providers. The
following providers are currently supported:

* GitHub
* Google (user data will be fetched from Google+)
* BitBucket

You have to register your SF deployment with the provider of your choice in order to enable
authentication. Please refer to the provider's documentation to do so. The OAuth2 protocol will
always require a callback URL regardless of the provider. This URL is https://fqdn/auth/login/oauth2/callback

Heres is an example of setting up the GitHub authentication:

Log on https://github.com and open https://github.com/settings/developers and select "register a new application"

You have to complete the form, the following parameters are mandatory:

* Application name: $fqdn
* Homepage URL: https://$fqdn/auth/login
* Authorization callback URL: https://$fqdn/auth/login/oauth2/callback

During configuration, the identity provider will generate a client ID and a client secret that are
needed to complete the configuration in /etc/software-factory/sfconfig.yaml.

.. code-block:: yaml

 authentication:
   oauth2:
     github:
       disabled: False
       client_id: "Client ID"
       client_secret: "Client Secret"


Apply the configuration by running sfconfig and open https://$fqdn/auth/login, select github, you will
be redirected to a github page to authorize application, validate. Github could now be used to authenticate
yours users.

The other OAuth2 providers can be set up in a similar fashion. Because of possible collisions between
user names and other details, it is advised to use only one provider per deployment.

The GitHub provider also lets you filter users logging in depending on the organizations they belong
to, with the field "github_allowed_organizations". Leave blank if not necessary.


OpenID authentication
^^^^^^^^^^^^^^^^^^^^^

Similarly, an OpenID provider can be used for authentication. Only a single OpenID provider
can be configured at a time, for example to use Launchpad:

.. code-block:: yaml

  authentication:
    openid:
      disabled: False
      server: https://login.launchpad.net/+openid
      login_button_text: "Log in with Launchpad"


OpenID Connect authentication
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

An OpenID Connect provider can be used for authentication. Likewise OAuth2, it requires an
application created on the provider to provides a client_id and client_secret. The callback
URL will be: https://fqdn/auth/login/openid_connect/callback .

Moreover it needs an issuer_url to retrieve the openid-configuration. Only a single OpenID
Connect provider can be configured at a time.

.. code-block:: yaml

  authentication:
    openid_connect:
        disabled: False
        issuer_url: https://accounts.google.com/
        login_button_text: "Log in with Google"
        client_id:
        client_secret:

The issuer_url can be tested using the */.well-known/openid-configuration* uri path, e.g.:
https://accounts.google.com/.well-known/openid-configuration

Single Sign-On with SAML2
^^^^^^^^^^^^^^^^^^^^^^^^^

Software Factory can be configured as a Service Provider and rely on an external
Identity Provider using the SAML2 protocol for users authentication.

The configuration of the single sign-on with SAML2 requires the operator to
know which user properties and attributes will be sent by the Identity Provider
to Software Factory, as they need to be mapped to the following user properties
in Software Factory's configuration file:

* **login**: the user name on Software Factory
* **email**: the email address
* **name**: the full name of the user
* **uid**: the unique identifier of the user on the Identity Provider

If the Identity Provider exposes the SSH public key(s) of its users in an
attribute, it is possible to map the keys to **ssh_keys**, and specify a
delimiter character to split the keys from this attribute value.

Here is an example configuration for a `Keycloak <https://www.keycloak.org/>`_
Identity Provider, using the default built-in user properties for "email" and
"name", and custom-defined attributes for "login" and "uid" (See
Keycloak's documentation for more details on how to create custom mappings for
SAML2):

.. code-block:: yaml

  authentication:
    SAML2:
      # set to true to activate
      disabled: true
      # Customize the login prompt here
      login_button_text: "Log in with Keycloak"
      # if the Identity Provider has a mapping for ssh keys, the delimiter
      # character will be used to split multiple keys
      key_delimiter: ','
      mapping:
        login: "username"
        email: "urn:oid:1.2.840.113549.1.9.1"
        name: "urn:oid:2.5.4.42"
        uid: "uid"
        ssh_keys: ""

Run ``sfconfig`` once to initialize the Service Provider metadata. You will
then be prompted with this message at the end of the run:

.. code-block:: bash

  Service Provider metadata is available at /etc/httpd/saml2/mellon_metadata.xml
  Once you have the Identity Provider metadata, run:
    sfconfig --set-idp-metadata <path/to/metadata.xml>

The file ``/etc/httpd/saml2/mellon_metadata.xml`` must then be forwarded to
the Identity Provider in order to register Software Factory as one of its Service
Providers. The Identity Provider's administrator should send you the identity
provider's metadata back in the form of a file or a URL. Re-run sfconfig with
the path to the metadata to finalize the configuration and activate the
Single Sign-On:

.. code-block:: bash

  sfconfig --set-idp-metadata <path/to/idp_metadata.xml>

Local user management
^^^^^^^^^^^^^^^^^^^^^

For simple deployments without an Identity Provider, you can manage the users
through the SFManager command-line utility (except for the default admin user, defined
in the sfconfig.yaml file). See SFmanager command-line
`User management </docs/sfmanager/sfmanager.html#user-management>`_ documentation for more details.

For example, to create a local user, run this command on the install-server:

.. code-block:: bash

    sfmanager user create --username demo --password demo
        --email demo@sftests.com --fullname "A local demo user"


Other authentication settings
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Cookie timeout
""""""""""""""

The SSO cookie timeout can also be changed:

.. code-block:: yaml

  authentication:
    # timeout of sessions in seconds
    sso_cookie_timeout: 43200

Identity provider data sync
^^^^^^^^^^^^^^^^^^^^^^^^^^^

By default, user data such as full name or email address are synchronized upon each successful login. Users
can disable this behavior in the user settings page (available from top right menu). When disabled, users
can manage the email address used in Software Factory service indepently from the identity provider data.
