.. _inspect_with_ara:

Using ARA to inspect SF playbooks runs
--------------------------------------

The environment is already set by sfconfig in /root/.ansible.cfg. Just run:

.. code-block:: bash

 ara-manage runserver -h 0.0.0.0 -p 55666

Then connect to http://sftests.com:55666
