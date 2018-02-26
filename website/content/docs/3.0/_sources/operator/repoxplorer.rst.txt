.. _repoxplorer-operator:

RepoXplorer service to browse hosted projects stats
===================================================

Software Factory bundles a service called repoXplorer that can be used
to provide a WEB interface to browse commits stats for hosted projects
on the platform.

RepoXplorer is an upstream project hosted `here <https://github.com/morucci/repoxplorer>`_.

Documentation can be found on `github <https://github.com/morucci/repoxplorer/blob/015c87543a01badf896df66e299a1b48e4aefbf7/README.md>`_.

The version currently integrated is the 0.8.0.

How to activate
---------------

This component is not deployed by default but can be activated by adding
the following components in */etc/software-factory/arch.yaml*:

.. code-block:: yaml

 - elasticsearch
 - repoxplorer

Then running:

.. code-block:: bash

 # sfconfig

The new component should be accessible via the Software Factory top menu under
the name repoXplorer.

Automatic configuration
-----------------------

Each time projects, repositories, groups are defined via the Software Factory's
resources backend the repoXplorer's config-update task will update the
repoXplorer default definitions file */etc/repoxplorer/default.yaml*.

In others words each projects displayed on the Software Factory welcome page
will be indexed and projects' stats will be browsable.

Manual configuration
--------------------

Manual configuration can be done via the SF config repository. Please have
a look to :ref:`repoxplorer manual configuration <repoxplorer-manual-configuration>`.
