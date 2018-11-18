OpenStack Summit Berlin Report
##############################

:date: 2018-11-16 06:00
:category: blog
:authors: tristanC

Here is my report on the 2018 OpenStack Summit in Berlin.

Day1 - Keynotes
---------------

Besides the many new developments in the OpenStack projects, my take away from
the first keynotes is that the summit is being renamed Open Infrastructure
to better represent the OpenStack Foundation's focus areas.
Nick Barcet announced[0] the next OSP version 14 as well as a
new edge use case design named Virtual Central Office (VCO)
which looks very exciting.

[0]: https://www.youtube.com/watch?v=Tph2sXIVNhY

|

After the keynotes, I spent most of my time on the Forum floor.
This is where projects' communities gathered to discuss various topics
around an etherpad in the same fashion as the old design summit.


Cross-project Open API 3.0 support
----------------------------------
At the API session[1] we discussed improvements to the api-ref documentation
schema to be directly used by clients and servers.
The improvements are a challenge because the openstacksdk has complex logics
baked in to support different micro versions.
Moreover, we want to be able to test the new schema definitions and
perhaps be able to generate clients' and servers' code from the definitions.
I mentioned the GraphQL implementation[2] we have been working on
with Gilles Dubreuil since Vancouver, but this is a much bigger project that
was out of scope for this discussion.
I'm personally very interested in being able to use a more rigorous
schema for the restfuzz project testing purpose.
I'm looking forward new developments in this area.

[1]: https://etherpad.openstack.org/p/api-berlin-forum-brainstorming

[2]: https://review.openstack.org/575898


Reusable Zuul Job Configurations
--------------------------------
At the Zuul Job[3] we discussed improvements to share Zuul jobs.
I was able to suggest supporting tagged projects in the Zuul configuration
instead of being forced to use the master version of zuul-jobs.
This should simplify the current deprecation period and we would tag
zuul-jobs along with Zuul to ensure compatibility and better stability.
I also proposed that we document cross-project sibbling installations
and encourage contributions in zuul-jobs so that new languages such as
javascript or rust could benefit from the cross-project gating system
of Zuul.
We also discussed improvements to mitigate the issues we had in
RDO CI when trying to re-use the upstream devstack and triple-o jobs.
James Blair proposed to support foreign required projects which
would greatly improve usability.

[3]: https://etherpad.openstack.org/p/BER-reusable-zuul-job-configurations

|

At the end of this first day I was too jetlagged to attend the Red Hat
party and went straight to my hotel to get a good night sleep. :)

Day 2 - Keynotes
----------------
At the second day's keynotes, Monty Taylor presented Zuul's project update[4]
and I was pleasantly surprised that two of the four new features were based
on Software Factory contributions: the React web interface and the Kubernetes
driver. Then Tobias Henkel gave a great presentation[5] on the CI needs of
BMW automotive software development and how they leverage
Zuul to accelerate and ensure a high quality standard. Besides the
compute resource scaling, for Tobias, the key feature of Zuul is the project
gating system which enables scaling development team.

[4]: https://www.youtube.com/watch?v=pqlTUZnS3Wg

[5]: https://www.youtube.com/watch?v=5yXvEleGgFE

|

After the keynote I went back to the Forum floor and had some interesting
walk-alley discussions:

Walk-Alley Discussions
----------------------
We found a solution to improve multi-tenant labels by designing an
'allowed-labels' option in the Zuul tenant configuration, and I went ahead
and proposed an implementation[6]. This enabled further discussion about
another solution on the Nodepool side.

As a follow-up I asked to merge the Nodepool code in Zuul to simplify this
kind of new feature and reduce code duplication. However, the Zuul core team
had a compeling argument for CI setup and how both projects are
effectively tested differently. In the end, we agreed that merging the
Zookeeper modules into a new nodepoollib repository would be a good compromise.

We also discussed how it can be difficult to debug complex issues such as
NODE_FAILURE errors which requires lots of hop. Tobias suggested that we could
attach a transaction-id to log message for tracing all the events related
to a single connection trigger event. Incidentally, Matthieu Huin has been
working on a very similar feature in Cauth recently.

Finally, we discussed how to improve Zuul's metric interface to enable native
Prometheus backend[7]. Different implementations have been proposed and the next
step is to collect all the existing metrics and find the best fit to refactor
the code.

[6]: https://review.openstack.org/617740

[7]: https://review.openstack.org/#/c/617220/

|

Then I gave a talk about log-classify and attended three more forum sessions:

Reduce your log noise using machine learning
--------------------------------------------
The presentation[8] went very well, more people than expected attended the talk.
We got some great feedback and it seems like many operators do not have
efficient log analysis in place.
One of the key requests is to support streaming
logs. We need a good internal interface to properly modelize such streams.
Another interesting feedback was about GDPR compliance and that log-classify
models is a good approach since the vectors are anonymised by design.

[8]: https://dirkmueller.github.io/presentation-berlin-log-classify/


A marketplace for sharing Zuul jobs and roles
---------------------------------------------
The BMW team presented[9] a new service[10] to provide a search interface and
jobs and roles usage metrics. This lead to a discussion about further
Zuul REST API improvements to better support such a use-case, and eventually
integrate the service directly into Zuul.

[9]:  https://etherpad.openstack.org/p/BER-zuul-jobs-marketplace

[10]: https://github.com/bmwcarit/zubbi


OpenDev feedback and missing features
-------------------------------------
The former openstack-infra team discussed[11] the OpenDev upcoming rename
and how review.openstack.org namespaces are going to be moved to the new
system. Source code replication to external systems is going to be improved
so that it can be managed on a per-project basis.

[11]: https://etherpad.openstack.org/p/BER-opendev-feedback-and-missing-features


Zuul - Project Onboarding
-------------------------
In the Zuul Project Onboarding, James Blair presented the new Zuul
QuickStart and how it can be used to quickly setup a test environment using
docker-compose.


RDO/Ceph community event
------------------------
At the end of the second day, I went to the RDO/Ceph community event.
It had a more relaxed atmosphere than the main venue and it was great to
meet the community in this setting with good music and German beer.
It was also a good opportunity to meet with the new community manager
Rain Leander who took over Rich Bowen's role recently.

I didn't attend the third day of the summit because it was already time
for me to go home. Once again, we have made great progress and I'm looking
forward to further developments.
Thanks you all for the great summit.
