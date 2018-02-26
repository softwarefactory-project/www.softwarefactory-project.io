.. _disable_gerrit:

Can I disable Gerrit ?
----------------------

As of now, Gerrit is mandatory in Software Factory for a couple of reasons:

* Managesf access control policies are based on Gerrit groups.
* The config repository is hosted on Gerrit with an integrated CI/CD workflow.

Gerrit will be made optional in a future release [1]_ of Software Factory

Note that it is possible to use Software Factory as a third party CI for
an external Gerrit or a GitHub organization. In this case, the gerrit server
is only used to host the config repository, and operators can bypass it
entirely by pushing config repository changes with the "git push" command
instead of "git review".

.. [1] To be determined
