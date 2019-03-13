Sprint 2019 Feb 22 to March 13 summary
######################################

:date: 2019-03-13 10:00
:modified: 2019-03-13 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

Regarding our contributions to Zuul and Nodepool:

* We continued work on Zuul's tenant-scoped admin REST API.The spec got its first
  +1 \o/ https://review.openstack.org/#/c/562321/. The patch chain reflects the
  latest version of the spec: https://review.openstack.org/#/q/status:open+project:openstack-infra/zuul+branch:master+topic:zuul_admin_web.
  We added an authorization rules engine. We added an endpoint that returns allowed
  actions for an authenticated user, this is meant to be consumed by frontends to
  display privileged actions depending on a user's privileges. We're looking into
  frontend integration and providing a small docker-compose file that would set up
  a keycloak instance so that people can play around with the change.
* We investigate a release_node task to release the nodeset before the end of the
  job, but there may be a better way to handle that use-case, like using a
  after-post-run for example.
* We updated the webtrigger patch according to upstream comment and removed the
* We continued to work on the zuul-runner utility and investigated how it can
  use nodepool standalone.custom parameters.
* We discussed OpenShift operator and BuildConfig on zuul-discuss.

Regarding Software Factory:

* We fixed issues related to custom deployment mode reported by users (e.g. multinode
  deployment without gerrit or greenfield letsencrypt setup)
* We updated the sf-3.2 release repository to include the Zuul security fix.
* The ELK stack bump 5.X patch is almost ready (working in CI) is in the review phase.
* We proposed a change to move the Hound (code search) configurator in managesf/configuration
  and add support of externally hosted repository (external gerrit / github).
* We packaged repoxplorer to SCL and integrated that new version in SF.
* We removed support of Elastic 2.X and add support for 5.X and 6.X in repoxplorer.
* We bootstrapped the distrojobs library and tried to took advantage of the new provide/require
  capability of Zuul.
