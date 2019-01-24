CI workflow offered by Zuul and Software Factory 
################################################

:date: 2019-01-24
:category: blog
:authors: Fabien Boucher

High level overview of Software Factory
=======================================

Zuul and Nodepool are at the heart of Software Factory. Zuul is a job
scheduler/runner and Nodepool is the node provisioner where Zuul execute jobs.

Software Factory provides out the box a fully functional Zuul and Nodepool
platform by providing default settings and addionnal optional components like a
logserver or an ELK stack. These components are provided with the specific
configuration to integrate well with Zuul and Nodepool.

Software Factory components
===========================

Here to put a schema with SF components mandatory and optional.

* Gerrit (optional)
* Zuul (mandatory)

  - Scheduler
  - Merger
  - Executor
  - Zookeeper
  - Gearman

* Nodepool (mandatory)

  - Launcher
  - Builder

* Logserver (optional)
* ARA (optional)
* ELK stack (optional)
* repoXplorer (optional)
* Logreduce (optional)
* Hound (code-search) (optional)
* Collaboration tools (Pastie, Etherpad, Mumble) (optional)

Software Factory can integrate with Code Review system such Gerrit
or Github.

It is worth mentioning that Software Factory relie on a config git repository
(configuration as code) where configuration is validated and deployed via 
Zuul.

Zuul/Nodepool
-------------

This sequence diagram shows Zuul and Nodepool components involved in
the run a single job from the trigger stimuli that is the Code-Review
proposed patch and the job result returned to the path author.

Need to rewrite with inskape and include:

* Align nodepool driver with what is proposed in SF
* logserver artifact export
* ELK export
* ARA report Build
* logreduce ?

.. image:: images/zuul-nodepool-workflow.png

This second diagram shows how a job is executed on the executor.

* Zuul executor creates an Ansible workspace

  - Inventory file 
  - Playbook 
  - Add additional roles (pull from git repos)
  - Clone dependent repositories

* Zuul executor run Ansible isolated in bubblewrap
* Ansible run job phases

  - pre-run

    + rsync repo source on the test node
    + validate the test node

  - run
  - post-run

    + build the job ARA report
    + export the logs/artifacts to the logserver
    + export the logs/artifacts to the ELK stack

