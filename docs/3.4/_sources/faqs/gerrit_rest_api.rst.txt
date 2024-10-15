.. _gerrit_rest_api:

How can I use the Gerrit REST API?
----------------------------------

The Gerrit REST API is open for queries by default on all Software Factory deployments.
There is an extensive documentation available online:

  https://gerrit-review.googlesource.com/Documentation/rest-api.html

The Gerrit API is available at the *https://fqdn/r/* endpoint for
non authenticated requests and for authenticated requests it is *https://fqdn/r/a/*.

To use the authenticated endpoint you have to create an API password first.
To do so, go to the **User Settings** page (upper right corner on the top menu)
and click on the button *Generate new API key*.

For example, getting open changed with cURL would be:

.. code-block:: bash

  curl "http://fqdn/r/changes/?q=status:open"

And to access a restricted resources with cURL would be:

.. code-block:: bash

  curl -u username:apikey https://fqdn/r/a/accounts/self/password.http
