.. _gerritlinks-user:

Gerrit comments link customisation
==================================

You can configure how Gerrit renders links in commit messages
by editing the **gerrit/commentlinks.yaml** file in the config repository:

* clone the config repository with git
* edit the gerrit/commentlinks.yaml, for example adding bugzilla.redhat.com:

.. code-block:: yaml

   commentlinks:
     - name: External_Bugzilla_addressing
       match: "BZ:\\s+#?(\\d+)"
       html: "BZ: <a href=\"https://bugzilla.redhat.com/show_bug.cgi?id=$2\">$2</a>"

* submit and merge the change.

.. note::

  This is just for automatic link rendering in the web interface of Gerrit.
  To actually update the issue on events, you should write a `firehose listener <firehose_user>`_.
