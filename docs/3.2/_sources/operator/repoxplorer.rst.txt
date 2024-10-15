.. _repoxplorer-operator:

RepoXplorer service to browse hosted projects stats
===================================================

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
