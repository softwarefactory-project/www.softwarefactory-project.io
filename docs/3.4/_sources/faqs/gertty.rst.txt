.. _gertty:

How can I use Gertty?
---------------------

After getting a Gerrit API key (as explained :ref:`in <gerrit_rest_api>`), use
the *basic* auth-type in gertty.yaml, e.g.:

.. code-block:: yaml

    servers:
      - name: sftests
        url: https://sftests.com/r/a/
        git-url: ssh://USER_NAME@sftests.com:29418
        auth-type: basic
        username: USER_NAME
        password: API_KEY
        git-root: ~/git/
