:date: 2018-02-07 19:30
:modified: 2018-02-07 19:30
:url:
:save_as: index.html
:authors: Fabien Boucher

.. raw:: html

    <h2>What is Software Factory?</h2>
    <table><tbody><tr><td><img src="./images/SoftwareFactory.png" /></td>
    <td>
      <b>Software Factory</b> is a software development forge.
      Software Factory provides an easy way to get everything you need to host,
      design, modify, test and build softwares; all of this pre-configured and
      usable immediately. Software Factory relies on several main components
      like <a href="https://zuul-ci.org">Zuul</a>,
      <a href="https://docs.openstack.org/infra/system-config/nodepool.html">Nodepool</a>
      and <a href="https://www.gerritcodereview.com/">Gerrit</a> to provide powerful
      Continuous Integration and developement workflows.
    </td></tr></tbody></table>

    <h2>Install It</h2>
    Supported releases:
    <table class="table table-hover">
      <thead>
        <th>Release date</th>
        <th>System</th>
        <th>Version</th>
        <th>Documentation</th>
      </thead>
      <tbody>
        <tr class='clickable-row' data-href='releases/3.0'>
          <td>Comming soon</td>
          <td>CentOS 7</td>
          <td>3.0</td>
          <td><a href="docs/3.0/operator/quickstart.html">Quickstart</a></td>
        </tr>
        <tr class='clickable-row' data-href='releases/2.7'>
          <td>20 Nov 2017</td>
          <td>CentOS 7</td>
          <td>2.7</td>
          <td><a href="docs/2.7/operator/quickstart.html">Quickstart</a></td>
        </tr>
      </tbody>
    </table>
    <script>
    $(document).ready(function($) {$(".clickable-row").click(function() {window.location = $(this).data("href");});});
    </script>

    <h2>Try It</h2>
    Public deployment:
    <ul class="list-group">
      <li class="list-group-item"><a href="https://softwarefactory-project.io">softwarefactory-project.io</a></li>
      <li class="list-group-item"><a href="https://review.rdoproject.org">review.rdoproject.org</a></li>
    </ul>
    Sandbox:
    <ul class="list-group">
      <li class="list-group-item">38.145.33.249 trysf.io</li>
    </ul>

    <h2>Get in touch</h2>
    <p><a href="https://www.redhat.com/mailman/listinfo/softwarefactory-dev">Mailing list</a></p>
    <p>Join <a href=http://webchat.freenode.net/?channels=%23softwarefactory">#softwarefactory</a> on FreeNode</p>
    <p><a href="https://tree.taiga.io/project/morucci-software-factory/backlog">Backlog</a></p>

