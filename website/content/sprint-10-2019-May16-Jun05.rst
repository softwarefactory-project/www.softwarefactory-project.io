Sprint 2019 May 16 to June 05 summary
######################################

:date: 2019-06-07 10:00
:modified: 2019-06-07 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

Regarding our contributions to Zuul and Nodepool:

* We investigated running Fedora distgit tests.yml with Zuul.
* We improved the webtrigger interface to support multiple pipeline for different nodeset and detect the default branch.
* We investigated a zuul-gateway service to convert AMQP event to Zuul jobs: https://pagure.io/fedora-project-config/blob/master/f/fedora-messaging . That gateway could also be used for webtrigger workload. 
* We helped fixes issues in Zuul CI for the containers and tox-remote jobs.
* We added tests to the React scripts bump for Zuul.
* We added a cleanup-run phase to Zuul jobs: https://review.opendev.org/#/q/topic:cleanup-phase .
* We improve the Pagure driver tests to add Cross gerrit/github/pagure tests
* We have updated the Elasticsearch Zuul driver to not by default export vars and exported vars

Regarding Software Factory:

* We continued to improve our multi-instances ci job to have a better tests coverage for tenants deployment.
* We prepared SF 3.3 release during the sprint and did a lot of testing around tenants deployment features.
* We upgraded sf-project.io, review.rdoproject.org and ansible.softwarefactory-project.io to SF 3.3 candidate
* We have investigated solution to build SF with distro-jobs on Copr instead of local Mock
* We have worked with Matthieu to try Keycloak OpenID with repoxplorer; currently we have backend support for JWT auth merged in repoxplorer
* We have investigated further how to replace cauth by keycloak:
  * Gerrit has a dedicated OpenID connect auth plugin that allows simple integration with Keycloak out of the box. However authenticated  REST API calls are not covered, I opened a RFE on github: https://github.com/davido/gerrit-oauth-provider/issues/50
  * No support out of the box for SSH key provisioning in Gerrit, but there are workarounds
  * Storyboard would require a significant rework to support OIDC. When mentioned on #storyboard, there are no plans to support it but they're open to it. On a side note, there is a OIDC plugin for taiga.
  * Repoxplorer would need frontend support. Given that the frontend is being rewritten at the moment, support will be added later.
  * Kibana has native OIDC auth plugins but they require a paying subscription. Kibana has no authentication on SF at the moment anyway.
  * Managesf has a few parts strongly tied to auth_pubtkt that would need rewriting (esp. gerrit API calls). A huge cleanup patch was proposed ahead of phase: https://softwarefactory-project.io/r/#/c/15672/
  * As for zuul, since we'll most likely be in charge of the frontend part of authentication, we can do it in a way that works best for us.
  * Generally speaking, we can rely on apache's "mod_auth_oidc" to interface services that can consume REMOTE_USER with an OIDC provider. * The downside would be that we might need to configure services as vhosts (to set up callbacks URI per service)

Regarding ARA:

* We released ARA 1.0: https://ara.recordsansible.org/blog/2019/06/04/announcing-the-release-of-ara-records-ansible-1.0/
* We moved the master branch to stable/0.x and the feature/1.0 to master
* We added support for customizing the API pagination
* We added missing properties to results for 'ignore_errors' and 'changed'
* We added or updated documentation for frequently asked questions, playbook names and labels and how to contribute to ARA
