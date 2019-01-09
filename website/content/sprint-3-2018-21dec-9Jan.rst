Sprint 2019 21 Dec to 09 Jan summary
####################################

:date: 2019-01-09 10:00
:modified: 2019-01-09 10:00
:category: blog
:authors: The Software Factory Team

Below are the tasks we worked on during our last sprint.

Regarding our contributions to Zuul and Nodepool:

* We added upstream testing for upload-to-pypi, and submitted a patch to improve this role's compatibility with devPI: https://review.openstack.org/#/c/629018/
* We merged Kubernetes and OpenShift support in Zuul.
* We merged a web-interface refactor to use React-redux store and implemented dispatch action to fetch job-output errors from the build page.

Regarding Software Factory:

* We worked on packaging the next version of zuul, lots of patches have been merged upstream.
* We investigated using buildah and podman to run software-factory in a box: https://www.softwarefactory-project.io/software-factory-container-with-buildah-and-podman.html (twitted by dwalsh https://twitter.com/rhatdan/status/1082717555029131264 )
* We documented how to use Zuul with OpenShift: https://www.softwarefactory-project.io/tech-preview-using-openshift-as-a-resource-provider.html
* We reworked cauth logging to add transaction id and better report login success/failure.
