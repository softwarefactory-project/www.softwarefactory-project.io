:date: 2018-02-07 19:30
:modified: 2018-02-07 19:30
:url:
:save_as: index.html
:authors: Fabien Boucher

.. image:: {filename}/images/SoftwareFactory.png
   :width: 40%
   :align: center

**Software Factory** (also called SF) is a software development forge.
Software Factory provides an easy way to get everything you need to host,
design, modify, test and build softwares; all of this pre-configured and
usable immediately. Software Factory relies on several main components
like Zuul_, Nodepool_, Gerrit_ to provide powerful Continuous Integration
and developement workflows.

.. _Zuul: https://github.com/openstack-infra/zuul
.. _Nodepool: https://github.com/openstack-infra/nodepool
.. _Gerrit: https://www.gerritcodereview.com/


Supported releases
------------------

.. raw:: html

    <table class="table table-hover">
      <thead>
        <th>System</th>
        <th>Version</th>
        <th>Release date</th>
      </thead>
      <tbody>
        <tr class='clickable-row' data-href='releases/3.0'>
          <td>CentOS 7</td>
          <td>3.0</td>
          <td>Comming soon</td>
        </tr>
        <tr class='clickable-row' data-href='releases/2.7'>
          <td>CentOS 7</td>
          <td>2.7</td>
          <td>20 Nov 2017</td>
        </tr>
      </tbody>
    </table>
    <script>
    jQuery(document).ready(function($) {$(".clickable-row").click(function() {window.location = $(this).data("href");});});
    </script>
