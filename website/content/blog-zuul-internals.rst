Zuul internals
##############

:date: 2018-09-14
:category: blog
:authors: tristanC

This article describes Zuul and Nodepool internals for an operator point of
view.


Events processing
-----------------

The scheduler is connected to gerrit events stream and it listen for github
webhook notification. When it receive an events, here is what happens:

- gerritconnection or githubconnection calls the **addEvent()** scheduler method
- scheduler processes events in the **Scheduler.run()** method
- scheduler retrieves the change in the **Scheduler.process_event_queue()**
  method. This calls the gerritconnection or githubconnection **getChange()**
  to fetch the change information within the scheduler service context.
- for each pipeline, the scheduler checks if the event matches the requirements
  and triggers of the pipeline with the pipeline
  manager **PipelineManager.eventMatches()** method
- if it does, the scheduler calls the **PipelineManager.addChange()** method

Here is what happens when the pipeline process events:

- First it logs "Starting queue processor: %s" % pipeline.name.
- Then in the **prepareItem()** method, it calls **scheduleMerge()**.
  This execute a merger:cat job over *gearman*.
  Either an executor or a merger service picks the job, tries to merge the
  change on the project git HEAD and load any zuul.yaml configuration.
- Once the configuration has been speculatively loaded, the pipeline manager
  can start processing the change. At that time, the
  change can be expanded in the status page and the job list is visible.
- For each job, the pipeline manager does:

  - Request Nodepool for the nodeset over *Zookeeper*.
  - Execute a 'executor:execute' job over *gearman*.
  - Record the build id associated with the job.

- The pipeline manager then logs "Finished queue processor: %s" % pipeline.name


Job execution
-------------

The executor service picks 'executor:execute' job request:

- It begins with the **ExecutorServer.executeJob()** method.
- The server merges the change and all the required projects (including the
  one with the jobs and the needed zuul roles).
- It setups the bubblewrap environment.
- Execute each pre-run playbook, then run, then post-run playbook.
- It send jobComplete event back to the scheduler over *gearman*.

Note that when playbook are running with a zuul_stream callback so that
task output is available over tcp from the slave, port 19885.

The executor also starts a finger service to forward the console stream.


Zuul web
--------

The web service enable different API over http:

- /status: returns the scheduler pipeline queues list
- /console-stream: when client connect over websocket to that service, zuul-web
  connect to the correct executor finger service and forward console stream.


Scheduler other events
----------------------

- reconfiguration: TODO
- onBuildCompleted: TODO
- onMergeFailed: TODO

Nodepool
--------

Nodepool wait for /request zookeeper nodes. It tries to assign existing node,
or create new one and lock them for the request.

Node status goes from:
- building
- ready
- in-use
- deleting

TODO: finish Nodepool documentation
